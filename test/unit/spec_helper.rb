require 'chefspec'
require 'chefspec/librarian'

RSpec.shared_context('sensu data bags') do
  let(:server_rabbitmq_credentials) do
    {
      'vhost' => '/server_vhost',
      'user' => 'server_user',
      'password' => 'server_password',
      'permissions' => '1 2 3'
    }
  end

  let(:ssl_data_bag_item) do
    {
      'ssl' => {
        'client' => {
          'cert' => '',
          'key' => ''
        },
        'server' => {
          'cert' => '',
          'key' => '',
          'cacert' => ''
        }
      },
      'config' => {
      },
      'enterprise' => {
      },
      'server' => {
        'rabbitmq' => server_rabbitmq_credentials
      }
    }
  end
end
