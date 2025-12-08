import os
import random
from datetime import datetime, timedelta

import pandas as pd
from faker import Faker
import numpy as np

# -----------------------
# Basic setup and config
# -----------------------

# Base directory = your project root (sql-pipeline-project)
BASE_DIR = os.path.dirname(os.path.dirname(__file__))

# Folder where we will save CSV files
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

fake = Faker()

# For reproducibility (same data each run)
random.seed(42)
np.random.seed(42)
Faker.seed(42)

# Row counts (these satisfy the requirements)
N_USERS = 50_000
N_PRODUCTS = 50_000
N_ORDERS = 100_000

# Date ranges for signups, product creation, orders etc.
START_DATE = datetime(2022, 1, 1)
END_DATE = datetime(2025, 1, 1)

# Some controlled vocabularies
COUNTRIES = ["India", "USA", "UK", "Germany", "Canada", "Australia"]
CITIES = {
    "India": ["Hyderabad", "Bengaluru", "Mumbai", "Delhi"],
    "USA": ["New York", "San Francisco", "Chicago"],
    "UK": ["London", "Manchester"],
    "Germany": ["Berlin", "Munich"],
    "Canada": ["Toronto", "Vancouver"],
    "Australia": ["Sydney", "Melbourne"],
}
CATEGORIES = {
    "Electronics": ["Mobiles", "Laptops", "Accessories"],
    "Clothing": ["Men", "Women", "Kids"],
    "Home": ["Kitchen", "Furniture"],
    "Sports": ["Outdoor", "Indoor"],
}
ORDER_STATUS = ["pending", "shipped", "delivered", "cancelled"]
PAYMENT_METHODS = ["card", "upi", "wallet", "cod"]
PAYMENT_STATUS = ["paid", "refunded", "failed"]


def random_date(start: datetime, end: datetime) -> datetime:
    """Pick a random datetime between start and end."""
    delta = end - start
    seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=seconds)


# -----------------------
# Users table
# -----------------------

def generate_users():
    users = []

    for user_id in range(1, N_USERS + 1):
        country = random.choice(COUNTRIES)
        city = random.choice(CITIES[country])
        signup = random_date(START_DATE, END_DATE)

        users.append(
            {
                "user_id": user_id,
                "first_name": fake.first_name(),
                "last_name": fake.last_name(),
                "email": fake.unique.email(),
                "signup_date": signup,
                "country": country,
                "city": city,
                "marketing_opt_in": random.choice([True, False]),
            }
        )

        if user_id % 10_000 == 0:
            print(f"Generated {user_id} users...")

    df = pd.DataFrame(users)
    output_path = os.path.join(DATA_DIR, "users.csv")
    df.to_csv(output_path, index=False)
    print(f"Saved {len(df)} users to {output_path}")


# -----------------------
# Products table
# -----------------------

def generate_products():
    products = []

    for product_id in range(1, N_PRODUCTS + 1):
        category = random.choice(list(CATEGORIES.keys()))
        subcategory = random.choice(CATEGORIES[category])
        created_at = random_date(START_DATE, END_DATE)
        price = round(random.uniform(5, 500), 2)

        products.append(
            {
                "product_id": product_id,
                "product_name": f"{subcategory} {fake.word()}",
                "category": category,
                "subcategory": subcategory,
                "price": price,
                "created_at": created_at,
                "is_active": random.choice([True, True, True, False]),  # mostly active
            }
        )

        if product_id % 10_000 == 0:
            print(f"Generated {product_id} products...")

    df = pd.DataFrame(products)
    output_path = os.path.join(DATA_DIR, "products.csv")
    df.to_csv(output_path, index=False)
    print(f"Saved {len(df)} products to {output_path}")


# -----------------------
# Orders, Order Items, Payments
# -----------------------

def generate_orders_items_payments():
    orders = []
    order_items = []
    payments = []

    order_item_id = 1
    payment_id = 1

    for order_id in range(1, N_ORDERS + 1):
        user_id = random.randint(1, N_USERS)
        order_date = random_date(START_DATE, END_DATE)

        # Make "delivered" and "shipped" more common
        status = random.choices(
            ORDER_STATUS,
            weights=[0.1, 0.2, 0.6, 0.1],  # pending, shipped, delivered, cancelled
            k=1
        )[0]

        payment_method = random.choice(PAYMENT_METHODS)

        # Shipping address (loosely related to user distribution)
        country = random.choice(COUNTRIES)
        city = random.choice(CITIES[country])

        # Number of items per order (1 to 5)
        n_items = random.randint(1, 5)
        order_total = 0.0

        for _ in range(n_items):
            product_id = random.randint(1, N_PRODUCTS)
            quantity = random.randint(1, 3)
            unit_price = round(random.uniform(5, 500), 2)
            discount_pct = random.choice([0, 0, 0, 5, 10, 15])  # mostly no discount

            line_amount = round(
                quantity * unit_price * (1 - discount_pct / 100),
                2
            )
            order_total += line_amount

            order_items.append(
                {
                    "order_item_id": order_item_id,
                    "order_id": order_id,
                    "product_id": product_id,
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "discount_pct": discount_pct,
                    "line_amount": line_amount,
                }
            )
            order_item_id += 1

        order_total = round(order_total, 2)

        orders.append(
            {
                "order_id": order_id,
                "user_id": user_id,
                "order_date": order_date,
                "status": status,
                "total_amount": order_total,
                "payment_method": payment_method,
                "shipping_country": country,
                "shipping_city": city,
            }
        )

        # Simple payment logic:
        # - if order is shipped/delivered, usually "paid"
        # - otherwise sometimes failed/refunded
        if status in ("shipped", "delivered"):
            payment_status = "paid"
        else:
            payment_status = random.choice(PAYMENT_STATUS)

        amount = order_total if payment_status != "failed" else 0.0
        payment_date = order_date + timedelta(hours=random.randint(0, 72))

        payments.append(
            {
                "payment_id": payment_id,
                "order_id": order_id,
                "payment_date": payment_date,
                "payment_status": payment_status,
                "amount": amount,
            }
        )
        payment_id += 1

        if order_id % 20_000 == 0:
            print(f"Generated {order_id} orders...")

    # Convert lists to DataFrames and save
    orders_df = pd.DataFrame(orders)
    order_items_df = pd.DataFrame(order_items)
    payments_df = pd.DataFrame(payments)

    orders_path = os.path.join(DATA_DIR, "orders.csv")
    order_items_path = os.path.join(DATA_DIR, "order_items.csv")
    payments_path = os.path.join(DATA_DIR, "payments.csv")

    orders_df.to_csv(orders_path, index=False)
    order_items_df.to_csv(order_items_path, index=False)
    payments_df.to_csv(payments_path, index=False)

    print(f"Saved {len(orders_df)} orders to {orders_path}")
    print(f"Saved {len(order_items_df)} order_items to {order_items_path}")
    print(f"Saved {len(payments_df)} payments to {payments_path}")


# -----------------------
# Main entry point
# -----------------------

if __name__ == "__main__":
    print("Starting synthetic data generation...")
    generate_users()
    generate_products()
    generate_orders_items_payments()
    print("All synthetic data generated successfully.")
