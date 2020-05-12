# Raspberry Pi 4 and CRT

State of affairs:

## 1. Composite SDTV output is disabled by default and will slow your system down. 


> enable_tvout (Pi 4B only)
> On the Raspberry Pi 4, composite output is disabled by default, due to the way the internal clocks are interrelated and allocated. Because composite video requires a very specific clock, setting that clock to the required speed on the Pi 4 means that other clocks connected to it are detrimentally affected, which slightly slows down the entire system. Since composite video is a less commonly used function, we decided to disable it by default to prevent this system slowdown.
> 
> To enable composite output, use the enable_tvout=1 option. As described above, this will detrimentally affect performance to a small degree.
> 
> On older Pi models, the composite behaviour remains the same.

Source: https://www.raspberrypi.org/documentation/configuration/config-txt/video.md

Here are the settings I use on my 20" Trinitron.

```
framebuffer_width=580
framebuffer_height=360 
enable_tvout=1
sdtv_mode=0
sdtv_aspect=1
disable_overscan=1
audio_pwm_mode=2
```

## 2. You will need a correct 4-pole 3.5mm to A/V RCA cable. 
There are many similar cables out there bundled with various A/V equipment, however most of them have ground on PIN1 and won't work, **but the cable we need must have composite video on PIN1.** The wiring of the other pins doesn't matter. So for example if PIN1 on the 3.5mm jack is wired to the white or red RCA connector it will still work as video, you just plug that into the TV Composite port instead of the yellow connector. This is the cable I used and can verify that it works and has the correct wiring: https://www.adafruit.com/product/2881

## 3. Now using `sdtv_mode=0/2` you will be in 480i. 
I recommend you keep it that way as a boot default and Emulationstation. Try playing your favorite ROMs first, and you will probably notice that the interlace shake is rather annoying, and there may be other issues. In experience Sakitoshi's tvout_smart and tvout_sharp shaders (https://github.com/Sakitoshi/retropie-crt-tvout/tree/master/to_configs/all/retroarch/shaders) do a great job of improving things quite a bit, but just make sure you **Shader #X Filter to Linear**. Try one of them as the only shader pass first. You may want to check out the configs in that repo as some platforms need additional tuning.


## 4. 240p - Background

You can boot directly into 240p by setting `sdtv_mode=16/18` for NTSC/PAL.

Mode switching between 480i and 240p via DRM/KMS is currently not possible. The `vc4` video driver used by `drm_kms_helper` will only add a single mode.

Source:
https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/vc4/vc4_drv.c#L283
https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/vc4/vc4_vec.c#L256

Installing X11 and adding ModeLines using xrandr also won't work. You will essentially resize the framebuffer, but the output will remain the same. The TV output is controlled by the VEC (encoder generating PAL or NTSC composite signal)

**TV mode selection is done by an atomic property on the encoder, because a drm_mode_modeinfo is insufficient to distinguish between PAL and PAL-M or NTSC and NTSC-J.**

Source: https://dri.freedesktop.org/docs/drm/gpu/vc4.html

The same applies to the changes needed for 240p output, they are:

- Integer number of lines (either 262 or 263) instead of 262.5 (x2 = 525) used for interlacing
- This will cause the VSync pulse to be sent at the end of a scanline and not in the middle of it, thus the scanlines will be retraced instead of being shifted down due to the ramp restart of the electron beam sawtooth wave.
- Change to the VSync and equalization pulses within the CSync signal sent during the blanking period

Source: https://www.hdretrovision.com/blog/2018/10/22/engineering-csync-part-1-setting-the-stage

**The only way that currently works more or less is using `tvservice` tool and enforcing the setting after retroarch has started**

In order to achieve 240p (`sdtv_mode=16/18`) the firmware does the following things:

A. Set the progressive scan bit in the `VEC_CONFIG2` register of the VEC register set:
https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/vc4/vc4_vec.c#L104

B. Remove the interlace flag for the mode:
https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/vc4/vc4_vec.c#L260

There are probably other steps needed as well.

Source: https://github.com/raspberrypi/firmware/issues/683#issuecomment-283179792

tvservice essentially sends VCHI message requesting the corresponding sdtv_mode

https://github.com/raspberrypi/userland/blob/2448644657e5fbfd82299416d218396ee1115ece/interface/vmcs_host/vc_sdtv.h#L60
https://github.com/raspberrypi/userland/blob/master/host_applications/linux/apps/tvservice/tvservice.c#L703
https://github.com/raspberrypi/userland/blob/master/interface/vmcs_host/vc_vchi_tvservice.c#L1213
https://github.com/raspberrypi/userland/blob/master/interface/vmcs_host/vc_vchi_tvservice.c#L698

I believe the VEC in the new BCM2711 SoC is the same as in the older BCM2835 therefore the register regions remain valid and this is why `tvservice` sitll works on RPi4.


## 240p - How to make it work

The good news is 240p per ROM/Platform is still possible!

I put together a simple script `vmodes_watcher.py` that runs in the background and monitors the value of a desired_mode file. If the file is modified, it waits for `retroarch` to start and then changes the screen to the desired mode with `tvservice`.

to install it do the following

```
$ cp runcommand-onend.sh  runcommand-onstart.sh  vmodes_watcher.py /opt/retropie/configs/all
$ mkdir /opt/retropie/configs/all/desired_mode
$ echo 'NTSC 4:3 P' > /opt/retropie/configs/all/desired_mode/value
$ sudo bash
# pip3 install watchdog psutil
# sed  "s/exit 0/su pi -c 'python3 -u \/opt\/retropie\/configs\/all\/vmodes_watcher.py &> \/var\/log\/vmodes_watcher.log' &\nexit 0/" /etc/rc.local
# reboot
```

Now try playing a ROM from a platform with 240p support (ex. NES). If everything installed correctly you should no longer see the flicker. Apply those tvout shaders previously mentioned and see which one you like best.

When you exit, Emulationstation should be back to 480i (assuming `sdtv_mode=0`)

### Setting desired_mode per ROM/platform

240p is the default mode for `runcommand-onstart.sh`. In order to force 480i for a particular game or platform you need to add the rom name or `all` in the corresponding `480i.txt` file. 

For example if I want all MAME ROMs to run in 480i I would do the following:
```
cat /opt/retropie/configs/mame-libretro/480i.txt 
all
```

Alternatively if I just wanted a particular ROM to run in 480i I would do this instead:

```
cat /opt/retropie/configs/mame-libretro/480i.txt 
umk3.zip
```

## Shaders

Check out the following post for instructions on tweaking the image for 224/240p and the pi_iq_horz_nearest_vert shader:

https://retropie.org.uk/forum/topic/11628/240p-and-mame-scaling/12


Sakitoshi has a great repo containing shaders, configurations and palletes for various platforms:

https://github.com/Sakitoshi/retropie-crt-tvout

