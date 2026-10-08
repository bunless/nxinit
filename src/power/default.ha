use rt;
//magic!
const REBOOT_MAGIC1: u64 = 0xfee1dead;
const REBOOT_MAGIC2: u64 = 0x28121969;
const RB_AUTOBOOT: u64 = 0x01234567;
const RB_POWER_OFF: u64 = 0x4321fedc;

export fn reboot() void = {
  rt::syscall(
    rt::SYS_reboot,
    REBOOT_MAGIC1,
    REBOOT_MAGIC2,
    RB_AUTOBOOT,
    0,
  );
};

export fn poweroff() void = {
  rt::syscall(
    rt::SYS_reboot,
    REBOOT_MAGIC1,
    REBOOT_MAGIC2,
    RB_POWER_OFF,
    0,
  );
};
