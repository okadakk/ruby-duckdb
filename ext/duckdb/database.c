#include "ruby-duckdb.h"

static void deallocate(void * ctx)
{
    rubyDuckDB *p = (rubyDuckDB *)ctx;

    duckdb_close(&(p->db));
    xfree(p);
}

static VALUE allocate(VALUE klass)
{
    rubyDuckDB *ctx = xcalloc((size_t)1, sizeof(rubyDuckDB));
    return Data_Wrap_Struct(klass, NULL, deallocate, ctx);
}

static VALUE duckdb_database_s_open(VALUE cDuckDBDatabase, VALUE str)
{
    rubyDuckDB *ctx;
    VALUE obj = allocate(cDuckDBDatabase);
    Data_Get_Struct(obj, rubyDuckDB, ctx);
    if (duckdb_open(NULL, &(ctx->db)) == DuckDBError)
    {
        rb_raise(rb_eRuntimeError, "Failed to open database"); /* FIXME */
    }
    return obj;
}


void init_duckdb_database(void) {
    VALUE cDuckDBDatabase = rb_define_class_under(mDuckDB, "Database", rb_cObject);
    rb_define_alloc_func(cDuckDBDatabase, allocate);
    rb_define_singleton_method(cDuckDBDatabase, "open", duckdb_database_s_open, 1);
}