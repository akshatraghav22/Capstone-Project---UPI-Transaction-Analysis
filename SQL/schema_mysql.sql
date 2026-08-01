-- ============================================================
-- UPI Transaction Analysis - Database Schema (DDL)
-- MySQL 8.0+ compatible
-- Module 3, Step 3: Database Design and Table Creation
-- ============================================================
-- Run this in MySQL Workbench (or `mysql -u root -p < schema_mysql.sql`)
-- Order matters: parent tables must be created before child
-- tables that reference them via FOREIGN KEY.
-- ============================================================

CREATE DATABASE upi_transactions
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE upi_transactions;


-- ---------- 1. customer_master (parent table, no FKs) ----------
CREATE TABLE customer_master (
    customer_id       VARCHAR(20)   PRIMARY KEY,
    full_name         VARCHAR(100)  NOT NULL,
    mobile_number     VARCHAR(10)   NOT NULL,   -- stored as VARCHAR to preserve leading zeros
    age               INT           NOT NULL,
    gender            VARCHAR(10)   NOT NULL,
    region            VARCHAR(20)   NOT NULL,
    date_joined       DATE          NOT NULL,
    is_business_user  BOOLEAN       NOT NULL,
    risk_score        DECIMAL(4,2)  NOT NULL,
    CONSTRAINT chk_cust_age CHECK (age BETWEEN 18 AND 100),
    CONSTRAINT chk_cust_risk CHECK (risk_score BETWEEN 0 AND 1)
) ENGINE=InnoDB;

-- ---------- 2. merchant_info (parent table, no FKs) ----------
CREATE TABLE merchant_info (
    merchant_id    VARCHAR(20)   PRIMARY KEY,
    merchant_name  VARCHAR(100)  NOT NULL,
    merchant_type  VARCHAR(30)   NOT NULL,
    region         VARCHAR(20)   NOT NULL,
    onboard_date   DATE          NOT NULL,
    risk_score     DECIMAL(4,2)  NOT NULL,
    CONSTRAINT chk_merch_risk CHECK (risk_score BETWEEN 0 AND 1)
) ENGINE=InnoDB;

-- ---------- 3. device_info (child of customer_master) ----------
CREATE TABLE device_info (
    device_id    VARCHAR(20)  PRIMARY KEY,
    customer_id  VARCHAR(20)  NOT NULL,
    device_type  VARCHAR(20)  NOT NULL,
    app_version  VARCHAR(10),
    is_rooted    BOOLEAN      NOT NULL,
    last_active  DATETIME(6)  NOT NULL,
    CONSTRAINT fk_device_customer FOREIGN KEY (customer_id)
        REFERENCES customer_master(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_device_customer (customer_id)
) ENGINE=InnoDB;

-- ---------- 4. upi_account_details (child of customer_master) ----------
CREATE TABLE upi_account_details (
    upi_id        VARCHAR(50)  PRIMARY KEY,
    customer_id   VARCHAR(20)  NOT NULL,
    bank_name     VARCHAR(30)  NOT NULL,
    account_type  VARCHAR(30)  NOT NULL,
    date_added    DATE         NOT NULL,
    status        VARCHAR(20)  NOT NULL,
    CONSTRAINT fk_upiacc_customer FOREIGN KEY (customer_id)
        REFERENCES customer_master(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_upiacc_customer (customer_id)
) ENGINE=InnoDB;

-- ---------- 5. customer_feedback_surveys (child of customer_master) ----------
CREATE TABLE customer_feedback_surveys (
    feedback_id         VARCHAR(20)  PRIMARY KEY,
    customer_id         VARCHAR(20)  NOT NULL,
    date_submitted       DATE         NOT NULL,
    feedback_text       TEXT,
    satisfaction_score  INT          NOT NULL,
    issue_type          VARCHAR(30),
    resolved            BOOLEAN      NOT NULL,
    CONSTRAINT chk_feedback_score CHECK (satisfaction_score BETWEEN 1 AND 5),
    CONSTRAINT fk_feedback_customer FOREIGN KEY (customer_id)
        REFERENCES customer_master(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_feedback_customer (customer_id)
) ENGINE=InnoDB;

-- ---------- 6. upi_transaction_history (the "hub" table - 4 FKs) ----------
CREATE TABLE upi_transaction_history (
    transaction_id    VARCHAR(20)    PRIMARY KEY,
    upi_id            VARCHAR(50)    NOT NULL,
    customer_id       VARCHAR(20)    NOT NULL,
    timestamp         DATETIME(6)    NOT NULL,
    amount            DECIMAL(12,2)  NOT NULL,
    transaction_type  VARCHAR(30)    NOT NULL,
    merchant_id       VARCHAR(20)    NULL,        -- nullable: only for merchant_payment/bill_pay
    counterparty_upi  VARCHAR(50),                -- not enforced as FK: counterparty may be external
    status            VARCHAR(20)    NOT NULL,
    device_id         VARCHAR(20)    NOT NULL,
    device_type       VARCHAR(20)    NOT NULL,
    channel           VARCHAR(20)    NOT NULL,
    fraud_flag        BOOLEAN        NOT NULL,
    reversal_flag     BOOLEAN        NOT NULL,
    failure_reason    VARCHAR(100),               -- nullable: only when status = 'failed'
    CONSTRAINT chk_txn_amount CHECK (amount > 0),
    CONSTRAINT fk_txn_customer FOREIGN KEY (customer_id)
        REFERENCES customer_master(customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_txn_merchant FOREIGN KEY (merchant_id)
        REFERENCES merchant_info(merchant_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_txn_upi FOREIGN KEY (upi_id)
        REFERENCES upi_account_details(upi_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_txn_device FOREIGN KEY (device_id)
        REFERENCES device_info(device_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_txn_customer (customer_id),
    INDEX idx_txn_merchant (merchant_id),
    INDEX idx_txn_device (device_id),
    INDEX idx_txn_timestamp (timestamp),
    INDEX idx_txn_status (status),
    INDEX idx_txn_fraud (fraud_flag)
) ENGINE=InnoDB;

-- ---------- 7. fraud_alert_history (child of upi_transaction_history) ----------
CREATE TABLE fraud_alert_history (
    alert_id         VARCHAR(20)  PRIMARY KEY,
    transaction_id   VARCHAR(20)  NOT NULL,
    alert_type       VARCHAR(30)  NOT NULL,
    alert_date       DATETIME(6)  NOT NULL,
    resolved         BOOLEAN      NOT NULL,
    resolution_date  DATETIME(6)  NULL,      -- nullable: only when resolved = TRUE
    remarks          TEXT,
    CONSTRAINT fk_alert_txn FOREIGN KEY (transaction_id)
        REFERENCES upi_transaction_history(transaction_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_alert_txn (transaction_id)
) ENGINE=InnoDB;
