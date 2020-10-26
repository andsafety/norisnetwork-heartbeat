# heartbeat::config
# @api private
#
# @summary It configures the heartbeat shipper
class heartbeat::config {
  $heartbeat_bin = '/usr/share/heartbeat/bin/heartbeat'

  $validate_cmd = $heartbeat::disable_configtest ? {
    true => undef,
    default => "${heartbeat_bin} test config -c %",
  }

  $heartbeat_config = delete_undef_values({
    'name'                      => $heartbeat::beat_name ,
    'fields_under_root'         => $heartbeat::fields_under_root,
    'fields'                    => $heartbeat::fields,
    'tags'                      => $heartbeat::tags,
    'queue'                     => $heartbeat::queue,
    'logging'                   => $heartbeat::logging,
    'output'                    => $heartbeat::outputs,
    'processors'                => $heartbeat::processors,
    'setup'                     => $heartbeat::setup,
    'heartbeat'                 => {
      'monitors'                 => $heartbeat::monitors,
    },
  })

  # Add 'monitoring' or 'xpack' section if supported (version >= 6.2.0)
  if ($facts['heartbeat_version'] != undef) {
    if (versioncmp($facts['heartbeat_version'], '7.2.0') >= 0) and ($heartbeat::monitoring) {
      $merged_config = deep_merge($heartbeat_config, {'monitoring' => $heartbeat::monitoring})
    }
    elsif (versioncmp($facts['heartbeat_version'], '6.2.0') >= 0) and ($heartbeat::monitoring) {
      $merged_config = deep_merge($heartbeat_config, {'xpack.monitoring' => $heartbeat::monitoring})
    }
    else {
      $merged_config = $heartbeat_config
    }
  } else {
    if ($heartbeat::major_version == '7' and (($heartbeat::package_ensure == 'present') or ($heartbeat::package_ensure == 'latest'))) {
      $merged_config = deep_merge($heartbeat_config, {'monitoring' => $heartbeat::monitoring})
    }
    elsif ($heartbeat::major_version == '6' and (($heartbeat::package_ensure == 'present') or ($heartbeat::package_ensure == 'latest'))) {
      $merged_config = deep_merge($heartbeat_config, {'xpack.monitoring' => $heartbeat::monitoring})
    }
    else {
      $merged_config = $heartbeat_config
    }
  }

  file { '/etc/heartbeat/heartbeat.yml':
    ensure       => $heartbeat::ensure,
    owner        => 'root',
    group        => 'root',
    mode         => $heartbeat::config_file_mode,
    content      => inline_template('<%= @merged_config.to_yaml()  %>'),
    validate_cmd => $validate_cmd,
  }
}
