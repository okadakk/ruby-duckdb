require 'date'
require_relative './converter'

module DuckDB
  # The DuckDB::PreparedStatement encapsulates connection with DuckDB prepared
  # statement.
  #
  #   require 'duckdb'
  #   db = DuckDB::Database.open('duckdb_database')
  #   con = db.connect
  #   sql ='SELECT name, email FROM users WHERE email = ?'
  #   stmt = PreparedStatement.new(con, sql)
  #   stmt.bind(1, 'email@example.com')
  #   stmt.execute
  class PreparedStatement
    include DuckDB::Converter

    RANGE_INT16 = -32768..32767
    RANGE_INT32 = -2147483648..2147483647
    RANGE_INT64 = -9223372036854775808..9223372036854775807

    def bind_hugeint(i, value)
      case value
      when Integer
        bind_varchar(i, value.to_s)
      else
        raise(ArgumentError, "2nd argument `#{value}` must be Integer.")
      end
    end

    # binds i-th parameter with SQL prepared statement.
    # The first argument is index of parameter.
    # The index of first parameter is 1 not 0.
    # The second argument value is to expected date.
    #
    #   require 'duckdb'
    #   db = DuckDB::Database.open('duckdb_database')
    #   con = db.connect
    #   sql ='SELECT name FROM users WHERE birth_day = ?'
    #   stmt = PreparedStatement.new(con, sql)
    #   stmt.bind(1, Date.today)
    #   #  or you can specify date string.
    #   # stmt.bind(1, '2021-02-23')
    def bind_date(i, value)
      case value
      when Date, Time
        date = value
      else
        begin
          date = Date.parse(value)
        rescue => e
          raise(ArgumentError, "Cannot parse argument value to date. #{e.message}")
        end
      end

      _bind_date(i, date.year, date.month, date.day)
    end

    # binds i-th parameter with SQL prepared statement.
    # The first argument is index of parameter.
    # The index of first parameter is 1 not 0.
    # The second argument value is to expected time value.
    #
    #   require 'duckdb'
    #   db = DuckDB::Database.open('duckdb_database')
    #   con = db.connect
    #   sql ='SELECT name FROM users WHERE birth_time = ?'
    #   stmt = PreparedStatement.new(con, sql)
    #   stmt.bind(1, Time.now)
    #   #  or you can specify time string.
    #   # stmt.bind(1, '07:39:45')
    def bind_time(i, value)
      case value
      when Time
        time = value
      else
        begin
          time = Time.parse(value)
        rescue => e
          raise(ArgumentError, "Cannot parse argument value to time. #{e.message}")
        end
      end

      _bind_time(i, time.hour, time.min, time.sec, time.usec)
    end

    # binds i-th parameter with SQL prepared statement.
    # The first argument is index of parameter.
    # The index of first parameter is 1 not 0.
    # The second argument value is to expected time value.
    #
    #   require 'duckdb'
    #   db = DuckDB::Database.open('duckdb_database')
    #   con = db.connect
    #   sql ='SELECT name FROM users WHERE created_at = ?'
    #   stmt = PreparedStatement.new(con, sql)
    #   stmt.bind(1, Time.now)
    #   #  or you can specify timestamp string.
    #   # stmt.bind(1, '2022-02-23 07:39:45')
    def bind_timestamp(i, value)
      case value
      when Time
        time = value
      else
        begin
          time = Time.parse(value)
        rescue => e
          raise(ArgumentError, "Cannot parse argument value to time. #{e.message}")
        end
      end

      _bind_timestamp(i, time.year, time.month, time.day, time.hour, time.min, time.sec, time.usec)
    end

    # binds i-th parameter with SQL prepared statement.
    # The first argument is index of parameter.
    # The index of first parameter is 1 not 0.
    # The second argument value is to expected ISO8601 time interval string.
    #
    #   require 'duckdb'
    #   db = DuckDB::Database.open('duckdb_database')
    #   con = db.connect
    #   sql ='SELECT value FROM intervals WHERE interval = ?'
    #   stmt = PreparedStatement.new(con, sql)
    #   stmt.bind(1, 'P1Y2D')
    def bind_interval(i, value)
      raise ArgumentError, "Argument `#{value}` must be a string." unless value.is_a?(String)

      hash = iso8601_interval_to_hash(value)

      months, days, micros = hash_to__append_interval_args(hash)

      _bind_interval(i, months, days, micros)
    end

    # binds i-th parameter with SQL prepared statement.
    # The first argument is index of parameter.
    # The index of first parameter is 1 not 0.
    # The second argument value is the value of prepared statement parameter.
    #
    #   require 'duckdb'
    #   db = DuckDB::Database.open('duckdb_database')
    #   con = db.connect
    #   sql ='SELECT name, email FROM users WHERE email = ?'
    #   stmt = PreparedStatement.new(con, sql)
    #   stmt.bind(1, 'email@example.com')
    def bind(i, value)
      case value
      when NilClass
        bind_null(i)
      when Float
        bind_double(i, value)
      when Integer
        case value
        when RANGE_INT64
          bind_int64(i, value)
        else
          bind_varchar(i, value.to_s)
        end
      when String
        blob?(value) ? bind_blob(i, value) : bind_varchar(i, value)
      when TrueClass, FalseClass
        bind_bool(i, value)
      when Time
        bind_varchar(i, value.strftime('%Y-%m-%d %H:%M:%S.%N'))
      when Date
        bind_varchar(i, value.strftime('%Y-%m-%d'))
      else
        raise(DuckDB::Error, "not supported type `#{value}` (#{value.class})")
      end
    end

    private

    def blob?(value)
      value.instance_of?(DuckDB::Blob) || value.encoding == Encoding::BINARY
    end
  end
end
