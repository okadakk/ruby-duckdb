require 'duckdb'
require 'date'

today = Date.today

DuckDB::Database.open do |db|
  db.connect do |con|
    con.query('CREATE TABLE dates (col_date DATE)')

    con.query("INSERT INTO dates VALUES ('#{today.strftime('%Y-%m-%d')}')")

    stmt = DuckDB::PreparedStatement.new(con, 'SELECT * FROM dates WHERE col_date = $1')
    stmt.bind_varchar(1, today.strftime('%Y-%m-%d'))

    #
    # STEP 1
    # stmt.bind_date で動くようにしたい。
    # dates テーブルの col_date カラムは DATE 型で、変数 today は Dateオブジェクトだから。
    #
    # stmt.bind_date(1, today)
    #
    # PreparedStatement クラスには、PreparedStatement#_bind_date(index, year, month, day) という
    # private method が存在している。
    # _bind_date メソッドを使って bind_date メソッドを実装してください。
    #
    # STEP 2
    # stmt.bind_date(1, Time.now) でも動くようにしてください。
    #
    # STEP 3
    # stmt.bind_date(1, '2021-12-02') でも動くようにしてください。
    #
    # STEP 4
    # stmt.bind_date(1, 'December, 2nd, 2021') でも
    # stmt.bind_date(1, '2nd December, 2021') でも動くようにしてください。
    #
    records = stmt.execute
    puts records.first.first
  end
end
