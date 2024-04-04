# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:rabbitmq_user_permissions).provider(:rabbitmqctl) do
  let(:params) do
    {
      name: 'foo@bar'
    }
  end
  let(:type_class) { Puppet::Type.type(:rabbitmq_user_permissions).provider(:rabbitmqctl) }
  let(:resource) { Puppet::Type.type(:rabbitmq_user_permissions).new(params) }
  let(:provider) { resource.provider }
  let(:instances) { type_class.instances }

  after do
    type_class.instance_variable_set(:@users, nil)
  end

  it 'matches user permissions from list' do
    allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
      bar 1 2 3
    EOT
    expect(provider.exists?).to eq(configure: '1', write: '2', read: '3')
  end

  it 'matches user permissions with empty columns' do
    allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
      bar			3
    EOT
    expect(provider.exists?).to eq(configure: '', write: '', read: '3')
  end

  it 'does not match user permissions with more than 3 columns' do
    allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
      bar 1 2 3 4
    EOT
    expect { provider.exists? }.to raise_error(Puppet::Error, %r{cannot parse line from list_user_permissions})
  end

  it 'does not match an empty list' do
    allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return ''
    expect(provider.exists?).to be_nil
  end

  it 'creates default permissions' do
    provider.instance_variable_set(:@should_vhost, 'bar')
    provider.instance_variable_set(:@should_user, 'foo')
    allow(type_class).to receive(:rabbitmqctl).with('set_permissions', '-p', 'bar', 'foo', "''", "''", "''")
    provider.create
  end

  it 'destroys permissions' do
    provider.instance_variable_set(:@should_vhost, 'bar')
    provider.instance_variable_set(:@should_user, 'foo')
    allow(type_class).to receive(:rabbitmqctl).with('clear_permissions', '-p', 'bar', 'foo')
    provider.destroy
  end

  { configure_permission: '1', write_permission: '2', read_permission: '3' }.each do |k, v|
    it "is able to retrieve #{k}" do
      allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
        bar 1 2 3
      EOT
      expect(provider.send(k)).to eq(v)
    end

    it "is able to retrieve #{k} after exists has been called" do
      allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
        bar 1 2 3
      EOT
      provider.exists?
      expect(provider.send(k)).to eq(v)
    end
  end
  { configure_permission: %w[foo 2 3],
    read_permission: %w[1 2 foo],
    write_permission: %w[1 foo 3] }.each do |perm, columns|
    it "is able to sync #{perm}" do
      allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
        bar 1 2 3
      EOT
      provider.resource[perm] = 'foo'
      allow(type_class).to receive(:rabbitmqctl).with('set_permissions', '-p', 'bar', 'foo', *columns)
      provider.send("#{perm}=".to_sym, 'foo')
    end
  end
  it 'onlies call set_permissions once' do
    allow(type_class).to receive(:rabbitmqctl_list).with('user_permissions', 'foo').and_return <<~EOT
      bar 1 2 3
    EOT
    provider.resource[:configure_permission] = 'foo'
    provider.resource[:read_permission] = 'foo'
    allow(type_class).to receive(:rabbitmqctl).with('set_permissions', '-p', 'bar', 'foo', 'foo', '2', 'foo').once
    provider.configure_permission = 'foo'
    provider.read_permission = 'foo'
  end
end
