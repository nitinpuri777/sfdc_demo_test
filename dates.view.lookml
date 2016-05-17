
# These three derived tables are used to create a date table that starts in 2000 and goes out for about 22 years. 
# Date tables are useful for joining into queries where you want to show each day even if there is no data for it (e.g. into the future).

# The first table, called two_numbers, creates a table with 2 rows. 
# The second table, called numbers creates a large table of numbers.
#   Each reference to two_numbers in the FROM clause creates a cross-product with the prior reference to two_numbers.
#   The name of the last reference to two_numbers is the total number of rows that will be in the final table: in this case, 8192.
# The final table, called dates, creates rows, which are dates, by adding each number in the previous table to Jan 1 2000.

# NOTE: This method is for Redshift. For other databases, the syntax may change slightly.

- view: two_numbers
  derived_table:
    sql: SELECT 1 as num UNION SELECT 2 as num
    distribution_style: ALL
    persist_for: 500 hours
    sortkeys: num
    
- view: numbers
  derived_table: 
    persist_for: 500 hours
    sortkeys: [number]
    distribution_style: EVEN
    sql: |
        SELECT 
          ROW_NUMBER() OVER (ORDER BY a2.num ) as number
        FROM ${two_numbers.SQL_TABLE_NAME} as a2,
            ${two_numbers.SQL_TABLE_NAME} as a4,
             ${two_numbers.SQL_TABLE_NAME} as a8,
             ${two_numbers.SQL_TABLE_NAME} as a16,
             ${two_numbers.SQL_TABLE_NAME} as a32,
             ${two_numbers.SQL_TABLE_NAME} as a64,
             ${two_numbers.SQL_TABLE_NAME} as a128,
             ${two_numbers.SQL_TABLE_NAME} as a256,
             ${two_numbers.SQL_TABLE_NAME} as a512,
             ${two_numbers.SQL_TABLE_NAME} as a1024,
             ${two_numbers.SQL_TABLE_NAME} as a2048,
             ${two_numbers.SQL_TABLE_NAME} as a4096,
             ${two_numbers.SQL_TABLE_NAME} as a8192

  fields:
  - dimension: number
    primary_key: true
    type: number

- view: dates
  derived_table:
    persist_for: 500 hours
    sortkeys: [date]
    distribution_style: ALL
    sql: |
      SELECT DATE('2000-01-01') + number as date FROM ${numbers.SQL_TABLE_NAME} as numbers
      
  fields:
  - dimension_group: event
    type: time
    timeframes: [date, week, month, year]
    convert_tz: false
    sql: ${TABLE}.date
    
  