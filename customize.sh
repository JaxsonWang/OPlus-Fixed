##########################################################################################
#
# MMT Extended Config Script
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maximum android version for your mod
# Uncomment DYNLIB if you want libs installed to vendor for oreo+ and system for anything older
# Uncomment PARTOVER if you have a workaround in place for extra partitions in regular magisk install (can mount them yourself - you will need to do this each boot as well). If unsure, keep commented
# Uncomment PARTITIONS and list additional partitions you will be modifying (other than system and vendor), for example: PARTITIONS="/odm /product /system_ext"
#MINAPI=21
#MAXAPI=25
#DYNLIB=true
#PARTOVER=true
#PARTITIONS=""

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  : # Remove this if adding to this function

  # Note that all files/folders in magisk module directory have the $MODPATH prefix - keep this prefix on all of your files/folders
  # Some examples:
  
  # For directories (includes files in them):
  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm_recursive $MODPATH/system/lib 0 0 0755 0644
  # set_perm_recursive $MODPATH/system/vendor/lib/soundfx 0 0 0755 0644

  # For files (not in directories taken care of above)
  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm $MODPATH/system/lib/libart.so 0 0 0644
  # set_perm /data/local/tmp/file.txt 0 0 644

  set_perm_recursive  $MODPATH/system/bin  0  2000  0755 0755
  # 设置权限，基本不要去动
  $MODPATH/system/bin/avbctl disable-verity --force >/dev/null && ui_print "- 已关闭DM校检" || abort "- 关闭DM校检失败！"
  $MODPATH/system/bin/avbctl disable-verification --force >/dev/null && ui_print "- 已关闭启动校检" || abort "- 关闭启动校检失败！"
}

##########################################################################################
# MMT Extended Logic - Don't modify anything after this
##########################################################################################

SKIPUNZIP=1
unzip -qjo "$ZIPFILE" 'common/functions.sh' -d $TMPDIR >&2
. $TMPDIR/functions.sh
