require_relative '../helper'

class RdsMysqlLogInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  DEFAULT_CONFIG = {
    access_key_id: 'dummy_access_key_id',
    secret_access_key: 'dummy_secret_access_key',
    region: 'ap-northeast-1',
    db_instance_identifier: 'test-mysql-id',
    refresh_interval: 2,
    pos_file: 'mysql-log-pos.dat',
  }

  def parse_config(conf = {})
    ''.tap{|s| conf.each { |k, v| s << "#{k} #{v}\n" } }
  end

  def create_driver(conf = DEFAULT_CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::RdsMysqlLogInput).configure(parse_config conf)
  end

  def iam_info_url
    'http://169.254.169.254/latest/meta-data/iam/security-credentials/'
  end

  def use_iam_role
    stub_request(:get, iam_info_url)
      .to_return(status: [200, 'OK'], body: "hostname")
    stub_request(:get, "#{iam_info_url}hostname")
      .to_return(status: [200, 'OK'],
                 body: {
                   "AccessKeyId" => "dummy",
                   "SecretAccessKey" => "secret",
                   "Token" => "token"
                 }.to_json)
  end

  def test_configure
    use_iam_role
    d = create_driver
    assert_equal 'dummy_access_key_id', d.instance.access_key_id
    assert_equal 'dummy_secret_access_key', d.instance.secret_access_key
    assert_equal 'ap-northeast-1', d.instance.region
    assert_equal 'test-mysql-id', d.instance.db_instance_identifier
    assert_equal 'mysql-log-pos.dat', d.instance.pos_file
    assert_equal 2, d.instance.refresh_interval
  end

  def test_audit_log_marker_update
    use_iam_role
    d = create_driver

    aws_client_stub = Aws::RDS::Client.new(stub_responses: {
      describe_db_log_files: {
        describe_db_log_files: [
          { log_file_name: 'server_audit.log', last_written: 123456789, size: 123 }
        ],
        marker: 'old_marker'
      },
      download_db_log_file_portion: {
        log_file_data: "20250403 19:41:01,ip-1-1-1-1,service,1.2.3.4,12345678,1234567890,QUERY,test_db,'UPDATE table SET id=123, updated_at=\'2025-04-03 19:38:08.681797\', is_weight_saved=1 WHERE table.id = 1234',0,,",
        marker: 'new_marker',
        additional_data_pending: false
      }
    })

    d.instance.instance_variable_set(:@rds, aws_client_stub)
    d.instance.instance_variable_set(:@pos_info, { 'server_audit.log' => 'old_marker' })
    
    d.run(timeout: 3, expect_emits: 1)
    events = d.events

    assert_equal(events[0][2]["log_file_name"], 'server_audit.log')
    assert_equal(events[0][2]["message"], "UPDATE table SET id=123, updated_at=\'2025-04-03 19:38:08.681797\', is_weight_saved=1 WHERE table.id = 1234")
  end

  def test_get_non_audit_log_files
    use_iam_role
    d = create_driver

    aws_client_stub = Aws::RDS::Client.new(stub_responses: {
      describe_db_log_files: {
        describe_db_log_files: [
          {
            log_file_name: 'error.log',
            last_written: 123456789,
            size: 123
          }
        ],
        marker: 'marker'
      },
      download_db_log_file_portion: {
        log_file_data: "2025-03-21T00:00:04.275032Z 4071946 [Warning] [MY-010055] [Server] IP address '1.2.3.4' could not be resolved: Name or service not known",
        marker: 'marker',
        additional_data_pending: false
      }
    })

    d.instance.instance_variable_set(:@rds, aws_client_stub)
    
    # Simulate an older pos_last_written_timestamp
    d.instance.instance_variable_set(:@pos_last_written_timestamp, 123456000)
    
    d.run(timeout: 3, expect_emits: 1)
    
    events = d.events
    
    assert_equal(events[0][2]["log_file_name"], 'error.log')
    assert_equal(events[0][2]["message"], "IP address '1.2.3.4' could not be resolved: Name or service not known")

    # Ensure non-audit logs used `pos_last_written_timestamp`
    assert_operator events[0][1].to_i, :>=, 123456000
  end

  def test_get_audit_log_files
    use_iam_role
    d = create_driver

    aws_client_stub = Aws::RDS::Client.new(stub_responses: {
      describe_db_log_files: {
        describe_db_log_files: [
          {
            log_file_name: 'server_audit.log',
            last_written: Time.now.to_i,
            size: 123
          }
        ],
        marker: 'marker'
      },
      download_db_log_file_portion: {
        log_file_data: "20250403 19:41:01,ip-1-1-1-1,service,1.2.3.4,12345678,1234567890,QUERY,test_db,'UPDATE table SET id=123, updated_at=\'2025-04-03 19:38:08.681797\', is_weight_saved=1 WHERE table.id = 1234',0,,",
        marker: 'marker',
        additional_data_pending: false
      }
    })

    d.instance.instance_variable_set(:@rds, aws_client_stub)
    d.run(timeout: 3, expect_emits: 1)
    
    events = d.events
    assert_equal(events[0][2]["log_file_name"], 'server_audit.log')
    assert_equal(events[0][2]["message"], "UPDATE table SET id=123, updated_at=\'2025-04-03 19:38:08.681797\', is_weight_saved=1 WHERE table.id = 1234")
  end
end
