# omarchy-dkms-audio-guard

An [Omarchy](https://omarchy.org/) shell service that watches the
dkms-built [`snd_hda_macbookpro`](https://github.com/davidjo/snd_hda_macbookpro)
speaker driver for Intel Macs with a Cirrus Logic CS8409 codec (tested on
an iMac19,1). The stock `snd_hda_codec_cs8409` driver finds no speakers on
these machines (`speaker_outs=0`), so the patched module has to be rebuilt
for every kernel update, and that rebuild can fail quietly:

- **headers missing** for the new kernel,
- the driver's `PRE_BUILD` step **can't download** the matching kernel
  sources from cdn.kernel.org (offline during the update),
- the patches **no longer apply** to a new kernel version.

The update itself still succeeds, and you only notice after the reboot,
when the speakers are silent again.

No bar icon, no UI. Every 10 minutes it checks every installed kernel,
including a freshly updated one you haven't booted yet. That way the
warning comes **before** the reboot. It sends one desktop notification per
boot if it finds a problem, pointing you at the bundled fix script. It
never runs the fix itself.

## What it detects

| Exit | Meaning |
|---|---|
| `0` | Build present for every installed kernel and loaded in the running one — or the driver isn't registered with dkms at all |
| `1` | An installed kernel lacks the build (running or pending), or the stock codec module is loaded instead of the dkms one |
| `2` | The build was reinstalled during this boot; reboot to load it |

## The fix

```
sudo ~/.config/omarchy/plugins/dkms-audio-guard/bin/omarchy-dkms-audio-guard
```

Runs `dkms install snd_hda_macbookpro/<version> -k <kernel>` for every
installed kernel that lacks the build and tells you which headers package
to install if they're missing. `--force` reinstalls for every installed
kernel. It never unloads a live audio module; reboot afterward if the
running kernel was rebuilt.

Note: the driver's build downloads ~150 MB of kernel sources from
cdn.kernel.org.

Read-only check, no root needed:

```
~/.config/omarchy/plugins/dkms-audio-guard/bin/omarchy-dkms-audio-guard --check
```

## Install

```
omarchy plugin add https://github.com/Thomster/omarchy-dkms-audio-guard.git --enable
```

## Requirements

- `dkms` and `snd_hda_macbookpro` registered with it
- the headers package for each installed kernel (e.g. `linux-omarchy-headers`)

To watch a different dkms codec driver, set `DKMS_AUDIO_NAME` (dkms package)
and `DKMS_AUDIO_KMOD` (module name as in `/sys/module`) when calling the
script.

## Related

Modeled on [omarchy-nvidia-dkms-guard](https://github.com/Thomster/omarchy-nvidia-dkms-guard),
which does the same for the NVIDIA DKMS driver.

## Changelog

Current version: **1.0.1**. See [CHANGELOG.md](CHANGELOG.md).

## How this came to be

This is a personal customization for my own Omarchy setup, built with the
help of [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding
agent). I'm not a professional plugin developer — please read through the
source before installing, and open an issue if something looks off.

## License

MIT
