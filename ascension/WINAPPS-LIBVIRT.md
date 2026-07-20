# WinApps on Ascension with libvirt

This host package uses libvirt only. Docker and Podman are not WinApps backends.

## Host verification

After activating the Ascension generation, run:

```bash
id -nG
test -r /dev/kvm && test -w /dev/kvm
virsh -c qemu:///system list --all
winapps-setup --help
xfreerdp --version
```

`id -nG` must include both `libvirtd` and `kvm`. Log out and back in, or reboot,
before testing new group membership.

Create `~/.config/winapps/winapps.conf` from
[`winapps.conf.example`](./winapps.conf.example). Keep `RDP_IP` empty for libvirt
guest discovery. Use `RDP_ASKPASS` rather than `RDP_PASS`; the real configuration
may invoke sensitive material and must remain outside Nix store and Git. Run:

```bash
chmod 0600 ~/.config/winapps/winapps.conf
```

The Windows account needs a real password. Windows Hello PIN alone is insufficient.

## Guest requirements

- Use Windows 10 or 11 Professional, Enterprise, or Server. Windows Home cannot host required RemoteApp/RDP functionality.
- Name VM `RDPWindows`. Use UEFI and TPM as appropriate for Windows 11.
- Install VirtIO storage and network drivers, then install and enable QEMU Guest Agent.
- Enable Windows Remote Desktop and create a complete local account with a password, not only a PIN.
- Apply WinApps official `RDPApps.reg` and its supporting libvirt guest setup steps. Do not apply Docker-only `Container.reg`.
- Log out from interactive Windows session before testing WinApps.
- Test normal FreeRDP connectivity before application discovery, then run `winapps-setup --user`.

## Hyprland and Wayland

Seamless RemoteApp windows use `xfreerdp` via XWayland; native Wayland RemoteApp/RAIL support remains incomplete. Full desktop mode may use SDL FreeRDP on Wayland. Expect possible invisible `RemoteApp Marker Window`, tooltip or shadow oddities, clipboard issues, and FreeRDP graphical glitches. Ascension adds a narrow maximize-event suppression rule for known Office classes; add classes only after observing them.

## Lifecycle

Keep autostart disabled unless explicitly needed. Inspect, start, and stop guest with:

```bash
virsh -c qemu:///system list --all
virsh -c qemu:///system start RDPWindows
virsh -c qemu:///system shutdown RDPWindows
```

Run `winapps-setup --user` again after installing Windows applications to refresh
application discovery. Generated launchers call `/run/current-system/sw/bin/winapps`
so they survive WinApps input updates and garbage collection.
