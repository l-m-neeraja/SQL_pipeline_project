import os
import duckdb

# Base directory (sql-pipeline-project)
BASE_DIR = os.path.dirname(os.path.dirname(__file__))

# Data and DB paths
DATA_DIR = os.path.join(BASE_DIR, "data")
DB_DIR = os.path.join(BASE_DIR, "db")
os.makedirs(DB_DIR, exist_ok=True)

DB_PATH = os.path.join(DB_DIR, "ecommerce.duckdb")

# Connect to DuckDB
con = duckdb.connect(DB_PATH)

def recreate_schema():
    print("Dropping existing tables (if any)...")

    con.execute("""
        DROP TABLE IF EXISTS payments;
        DROP TABLE IF EXISTS order_items;
        DROP TABLE IF EXISTS orders;
        DROP TABLE IF EXISTS products;
        DROP TABLE IF EXISTS users;
    """)

    print("Creating tables...")

    con.execute("""
        CREATE TABLE users (
            user_id INTEGER PRIMARY KEY,
            first_name VARCHAR,
            last_name VARCHAR,
            email VARCHAR,
            signup_date TIMESTAMP,
            country VARCHAR,
            city VARCHAR,
            marketing_opt_in BOOLEAN
        );
    """)

    con.execute("""
        CREATE TABLE products (
            product_id INTEGER PRIMARY KEY,
            product_name VARCHAR,
            category VARCHAR,
            subcategory VARCHAR,
            price DECIMAL(10,2),
            created_at TIMESTAMP,
            is_active BOOLEAN
        );
    """)

    con.execute("""
        CREATE TABLE orders (
            order_id INTEGER PRIMARY KEY,
            user_id INTEGER REFERENCES users(user_id),
            order_date TIMESTAMP,
            status VARCHAR,
            total_amount DECIMAL(12,2),
            payment_method VARCHAR,
            shipping_country VARCHAR,
            shipping_city VARCHAR
        );
    """)

    con.execute("""
        CREATE TABLE order_items (
            order_item_id INTEGER PRIMARY KEY,
            order_id INTEGER REFERENCES orders(order_id),
            product_id INTEGER REFERENCES products(product_id),
            quantity INTEGER,
            unit_price DECIMAL(10,2),
            discount_pct DECIMAL(5,2),
            line_amount DECIMAL(12,2)
        );
    """)

    con.execute("""
        CREATE TABLE payments (
            payment_id INTEGER PRIMARY KEY,
            order_id INTEGER REFERENCES orders(order_id),
            payment_date TIMESTAMP,
            payment_status VARCHAR,
            amount DECIMAL(12,2)
        );
    """)


def load_csvs():
    print("Loading data from CSV files...")

    con.execute(f"""
        COPY users FROM '{os.path.join(DATA_DIR, "users.csv")}' (AUTO_DETECT TRUE);
    """)

    con.execute(f"""
        COPY products FROM '{os.path.join(DATA_DIR, "products.csv")}' (AUTO_DETECT TRUE);
    """)

    con.execute(f"""
        COPY orders FROM '{os.path.join(DATA_DIR, "orders.csv")}' (AUTO_DETECT TRUE);
    """)

    con.execute(f"""
        COPY order_items FROM '{os.path.join(DATA_DIR, "order_items.csv")}' (AUTO_DETECT TRUE);
    """)

    con.execute(f"""
        COPY payments FROM '{os.path.join(DATA_DIR, "payments.csv")}' (AUTO_DETECT TRUE);
    """)

    print("CSV data loaded into DuckDB successfully!")


if __name__ == "__main__":
    print("Starting database setup...")
    recreate_schema()
    load_csvs()
    print(f"Database is ready at: {DB_PATH}")
