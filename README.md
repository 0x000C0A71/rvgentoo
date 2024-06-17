This overlay is to house ebuilds for getting Gentoo running on my riscv boards (only VF2 for now).

# Adding it to your gentoo system
Add this as /etc/portage/repos.conf/rvgentoo.conf, and then you can update it with `emaint sync -r rvgentoo`
```
[rvgentoo]
location = /var/db/repos/rvgentoo
sync-type = git
sync-uri = https://github.com/0x000C0A71/rvgentoo.git
```

# The IMG-GPU driver is limited
In most of the other images for the VF2, there are 2 userspace drivers:
- the proprietary IMG-GPU driver that is shipped as a binary.
- An old version of imagination's open source mesa driver

The former only provides vulkan and opencl and is the one for which an ebuild exists here.
The latter is the more usable of the two, but I've decided to not create an ebuild for that one for the following reasons:
- Building such an old version of mesa has its difficulties, as it requires old versions of all its dependencies.
- The newer versions of imagination's open source mesa driver are incompatible with the older kernel driver included in starfive's linux fork
- Considering imagination's mesa driver is already merged, and their kernel driver was merged in version 6.8 of the kernel, imagination's open source implementation is likely to get included in starfive's linux fork the next time they rebase.
- Considering starfive has made [great progress in their upsreaming efforts](https://rvspace.org/en/project/JH7110_Upstream_Plan), it might not be all too long before we can use upstream linux on our Visionfive 2s which ship with imagination's open source rouge driver
- I'm using my Visionfive 2 with an external GPU, so I, personally, stand little to nothing to gain from getting their old mesa driver to compile (i.e. I can't be bothered).
