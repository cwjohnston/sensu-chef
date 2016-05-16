require_relative "spec_helper"
require_relative "common_examples"

RSpec.shared_examples 'rabbitmq' do
  ssl_directory = '/etc/rabbitmq/ssl'

  context 'with ssl enabled' do
    before do
      chef_run.node.set['sensu']['use_ssl'] = true
      chef_run.converge(described_recipe)
    end

    it 'overrides rabbitmq ssl attributes' do
      expect(chef_run.node["rabbitmq"]["ssl"]).to eq(true)
      expect(chef_run.node["rabbitmq"]["ssl_port"]).to eq(5671)
      expect(chef_run.node["rabbitmq"]["ssl_verify"]).to eq("verify_peer")
      expect(chef_run.node["rabbitmq"]["ssl_fail_if_no_peer_cert"]).to eq(true)
    end

    it 'creates rabbitmq ssl directory' do
      expect(chef_run).to create_directory(ssl_directory).with(
        :recursive => true
      )
    end

    %w( cacert cert key ).each do |item|
      item_path = File.join(ssl_directory, "#{item}.pem")
      it "creates the #{item} file" do
        expect(chef_run).to create_file(item_path).with(
          :group => "rabbitmq",
          :mode => 0640
        )
      end

      it "overrides the rabbitmq.ssl_#{item} attribute with value #{item_path}" do
        expect(chef_run.node["rabbitmq"]["ssl_#{item}"]).to eq(item_path)
      end
    end
  end

  context 'with ssl disabled' do
    before do
      chef_run.node.set['sensu']['use_ssl'] = false
      chef_run.converge(described_recipe)
    end

    it 'does not override rabbitmq ssl attributes' do
      expect(chef_run.node["rabbitmq"]["ssl"]).to eq(false)
    end
  end

  context 'general rabbitmq credentials' do
    it 'adds rabbitmq vhost' do
      expect(chef_run).to add_rabbitmq_vhost('sensu')
    end

    it 'adds rabbitmq user' do
      expect(chef_run).to add_rabbitmq_user('sensu').with(
        :password => 'password',
        :permissions => '.* .* .*'
      )
    end

  end

  context 'with service-specific rabbitmq configuration' do
    it 'adds service-specific rabbitmq vhost' do
      expect(chef_run).to add_rabbitmq_vhost(server_rabbitmq_credentials['vhost'])
    end

    it 'adds service-specific rabbitmq user' do
      expect(chef_run).to add_rabbitmq_user(server_rabbitmq_credentials['user']).with(
        :password => server_rabbitmq_credentials['password'],
        :permissions => server_rabbitmq_credentials['permissions']
      )
    end
  end

end

describe "sensu::rabbitmq" do

  include_context("sensu data bags")

  context 'debian-derived platforms' do

    let(:chef_run) do
      ChefSpec::ServerRunner.new(:platform => "ubuntu", :version => "12.04") do |node, server|
        server.create_data_bag("sensu", ssl_data_bag_item)
      end
    end

    it_behaves_like('rabbitmq')

    context 'value of attribute sensu.rabbitmq.use_esl_erlang is false' do
      it 'installs erlang-nox package but does not install esl-erlang package' do
        chef_run.node.set['sensu']['rabbitmq']['use_esl_erlang'] = false
        chef_run.converge(described_recipe)
        expect(chef_run).to_not install_package('esl-erlang')
        expect(chef_run).to install_package('erlang-nox')
      end
    end

    context 'value of attribute sensu.rabbitmq.use_esl_erlang is true' do
      it 'installs both the esl-erlang and erlang-nox packages' do
        chef_run.node.set['sensu']['rabbitmq']['use_esl_erlang'] = true
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package('esl-erlang')
        expect(chef_run).to install_package('erlang-nox')
      end
    end
  end

  context 'rhel5 platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(:platform => "redhat", :version => "5.10") do |node, server|
        server.create_data_bag("sensu", ssl_data_bag_item)
      end
    end

    it_behaves_like('rabbitmq')

    context 'value of attribute sensu.rabbitmq.use_esl_erlang is false' do
      it 'installs erlang package but does not install esl-erlang' do
        chef_run.node.set['sensu']['rabbitmq']['use_esl_erlang'] = false
        chef_run.converge(described_recipe)
        expect(chef_run).not_to install_package('esl-erlang')
        expect(chef_run).to install_package('erlang')
      end
    end

    context 'value of attribute sensu.rabbitmq.use_esl_erlang is true' do
      it 'installs erlang package but does not install esl-erlang because RHEL5 is not supported by ESL repo' do
        chef_run.node.set['sensu']['rabbitmq']['use_esl_erlang'] = true
        chef_run.converge(described_recipe)
        expect(chef_run).not_to install_package('esl-erlang')
        expect(chef_run).to install_package('erlang')
      end
    end
  end

  context 'rhel6 platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(:platform => "redhat", :version => "6.6") do |node, server|
        server.create_data_bag("sensu", ssl_data_bag_item)
      end
    end

    it_behaves_like('rabbitmq')

    context 'value of attribute sensu.rabbitmq.use_esl_erlang is false' do
      it 'installs erlang package but does not install esl-erlang' do
        chef_run.node.set['sensu']['rabbitmq']['use_esl_erlang'] = false
        chef_run.converge(described_recipe)
        expect(chef_run).not_to install_package('esl-erlang')
        expect(chef_run).to install_package('erlang')
      end
    end

    context 'value of attribute sensu.rabbitmq.use_esl_erlang is true' do
      it 'installs both erlang and esl-erlang packages' do
        chef_run.node.set['sensu']['rabbitmq']['use_esl_erlang'] = true
        chef_run.converge(described_recipe)
        expect(chef_run).to install_package('esl-erlang')
        expect(chef_run).to install_package('erlang')
      end
    end
  end
end
