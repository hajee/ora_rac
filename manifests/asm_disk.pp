# == Class: ora_rac::asm_disk
#
# === Parameters
#
# name      partition name if the form /dev/sda:1
# name      asm name name
# start     start of the partition. If not specified or undef, it will default to the
#           first available sector on the disk.
# end       end of the partition. If not specfied or undef, it will default to the last
#           available block on the disk. Therefore filling the whole disk.
#
# === Variables
#
# === Authors
#
# Bert Hajee <hajee@moretIA.com>
#
#
define ora_rac::asm_disk(
  $raw_device,
  $start    = undef,
  $end      = undef,
)
{
  #
  # Validation
  #
  assert_type(Pattern[/.*\:.*/], $raw_device) |$e, $a| { fail "raw_device is ${a}, but you must specify a device with a partition number"}
  assert_type(Variant[String[0],Pattern[/\d.*\S?[%|k|K|m|M|g|G][b|B]?/]],$start )  |$e, $a| { fail "start is ${a}, but you must be either undef or a valid size string"}
  assert_type(Variant[String[0],Pattern[/\d.*\S?[%|k|K|m|M|g|G][b|B]?/]],$end ) |$e, $a| { fail "end is ${a}, but you must be either undef or a valid size string"}

  #
  # Manipulation and translation of parameters
  #
  $_device_array    = split($raw_device,'[:]')
  $device_name      = $_device_array[0]
  $partition_number = $_device_array[1]
  $mapped_device    = regsubst($dev,'\/dev\/mapper\/.*', '') != $dev
  #
  #
  # Mapped devices use the 'p1' and 'p2' extensions for partitions
  #
  if $mapped_device {
    $device         = "${device_name}p${partition_number}"
  } else {
    $device         = "${device_name}${partition_number}"
  }

  partition_table{$device_name:
    ensure  => 'gpt',
  }->

  partition{$raw_device:
    ensure    => 'present',
    part_name => 'primary',
    start     => $start,
    end       => $end,
  }->

  exec{"/usr/sbin/oracleasm createdisk ${name} ${device}":
    unless    => "/usr/sbin/oracleasm querydisk -v ${device}",
    require   => Service['oracleasm'],
  }

}