# frozen_string_literal: true

Puppet::Type.newtype(:rabbitmq_exchange) do
  desc <<~DESC
    Native type for managing rabbitmq exchanges

    @example Create a rabbitmq_exchange
     rabbitmq_exchange { 'myexchange@myvhost':
       user        => 'dan',
       password    => 'bar',
       type        => 'topic',
       ensure      => present,
       internal    => false,
       auto_delete => false,
       durable     => true,
       arguments   => {
         hash-header => 'message-distribution-hash'
       }
     }
  DESC

  ensurable do
    desc 'Whether the resource should be present or absent'
    defaultto(:present)
    newvalue(:present) do
      provider.create
    end
    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:name, namevar: true) do
    desc 'Name of exchange'
    newvalues(%r{^\S*@\S+$})
  end

  newparam(:type) do
    desc 'Exchange type to be set *on creation*'
    newvalues(%r{^\S+$})
  end

  newparam(:durable) do
    desc 'Exchange durability to be set *on creation*'
    newvalues(%r{^\S+$})
    defaultto 'false'
  end

  newparam(:auto_delete) do
    desc 'Exchange auto delete option to be set *on creation*'
    newvalues(%r{^\S+$})
    defaultto 'false'
  end

  newparam(:internal) do
    desc 'Exchange internal option to be set *on creation*'
    newvalues(%r{^\S+$})
    defaultto 'false'
  end

  newparam(:arguments) do
    desc 'Exchange arguments example: {"hash-header": "message-distribution-hash"}'
    defaultto({})
  end

  newparam(:user) do
    desc 'The user to use to connect to rabbitmq'
    defaultto('guest')
    newvalues(%r{^\S+$})
  end

  newparam(:password) do
    desc 'The password to use to connect to rabbitmq'
    defaultto('guest')
    newvalues(%r{\S+})
  end

  validate do
    raise ArgumentError, "must set type when creating exchange for #{self[:name]} whose type is #{self[:type]}" if self[:ensure] == :present && self[:type].nil?
  end

  autorequire(:rabbitmq_vhost) do
    [self[:name].split('@')[1]]
  end

  autorequire(:rabbitmq_user) do
    [self[:user]]
  end

  autorequire(:rabbitmq_user_permissions) do
    ["#{self[:user]}@#{self[:name].split('@')[1]}"]
  end
end
