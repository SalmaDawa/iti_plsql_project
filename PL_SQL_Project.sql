--CREATING TABLES--
CREATE TABLE CLIENTS ( CLIENT_ID NUMBER(4) PRIMARY KEY,
                                        CLIENT_NAME VARCHAR(400), 
                                        CLIENT_ADDRESS VARCHAR(4000), 
                                        CLIENT_NOTES VARCHAR(4000) );

CREATE TABLE CONTRACTS ( CONTRACT_ID NUMBER(8) PRIMARY KEY,
                                            CONTRACT_STARTDATE DATE,
                                            CONTRACT_ENDDATE DATE,
                                            PAYMENTS_INSTALLMENTS_NO NUMBER(8),
                                            CONTRACT_TOTAL_FEES NUMBER(20, 2),
                                            CONTRACT_DEPOSIT_FEES NUMBER(20, 2),
                                            CLIENT_ID NUMBER(4),
                                            CONTRACT_PAYMENT_TYPE VARCHAR(400),
                                            NOTES VARCHAR(4000) );

CREATE TABLE INSTALLMENTS_PAID ( INSTALLMENT_ID NUMBER(8) PRIMARY KEY,
                                                        CONTRACT_ID NUMBER(8),
                                                        INSTALLMENT_DATE DATE,
                                                        INSTALLMENT_AMOUNT NUMBER(20, 2),
                                                        PAID NUMBER(20, 2) );

ALTER TABLE CONTRACTS
ADD CONSTRAINT FK_ID
FOREIGN KEY (CLIENT_ID) REFERENCES CLIENTS (CLIENT_ID);

ALTER TABLE INSTALLMENTS_PAID
ADD CONSTRAINT FK_CONT_ID
FOREIGN KEY (CONTRACT_ID) REFERENCES CONTRACTS (CONTRACT_ID);

ALTER TABLE INSTALLMENTS_PAID 
MODIFY PAID DEFAULT 0;

--INSERTING INTO CLIENTS TABLE--
INSERT ALL
    INTO CLIENTS (CLIENT_ID, CLIENT_NAME, CLIENT_ADDRESS)
        VALUES ( 1, 'CLIENT 1', 'CAIRO' ) 
    INTO CLIENTS (CLIENT_ID, CLIENT_NAME, CLIENT_ADDRESS)
        VALUES ( 2, 'CLIENT 2', 'ALEX' )
    INTO CLIENTS (CLIENT_ID, CLIENT_NAME, CLIENT_ADDRESS)
        VALUES ( 3, 'CLIENT 3', 'CAIRO' )
    INTO CLIENTS (CLIENT_ID, CLIENT_NAME, CLIENT_ADDRESS)
        VALUES ( 4, 'CLIENT 4', 'Cairo' )
        SELECT * FROM DUAL;

--INSERTING INTO CONTRACTS TABLE--
INSERT ALL
    INTO CONTRACTS ( CONTRACT_ID, 
                                CONTRACT_STARTDATE, CONTRACT_ENDDATE, 
                                CONTRACT_TOTAL_FEES, CONTRACT_DEPOSIT_FEES, 
                                CLIENT_ID, CONTRACT_PAYMENT_TYPE)
        VALUES (101, 
                    TO_DATE('01.01.2021', 'DD.MM.YYYY'), TO_DATE('01.01.2023', 'DD.MM.YYYY'),
                    500000, NULL,
                    1, 'ANNUAL')
                    
    INTO CONTRACTS ( CONTRACT_ID, 
                                CONTRACT_STARTDATE, CONTRACT_ENDDATE, 
                                CONTRACT_TOTAL_FEES, CONTRACT_DEPOSIT_FEES, 
                                CLIENT_ID, CONTRACT_PAYMENT_TYPE)
        VALUES (102, 
                    TO_DATE('01.03.2021', 'DD.MM.YYYY'), TO_DATE('01.03.2024', 'DD.MM.YYYY'),
                    600000, 10000,
                    2, 'QUARTER')
                    
    INTO CONTRACTS ( CONTRACT_ID, 
                                CONTRACT_STARTDATE, CONTRACT_ENDDATE, 
                                CONTRACT_TOTAL_FEES, CONTRACT_DEPOSIT_FEES, 
                                CLIENT_ID, CONTRACT_PAYMENT_TYPE)
        VALUES (103, 
                    TO_DATE('01.05.2021', 'DD.MM.YYYY'), TO_DATE('01.05.2023', 'DD.MM.YYYY'),
                    400000, 50000,
                    3, 'QUARTER')
                    
    INTO CONTRACTS ( CONTRACT_ID, 
                                CONTRACT_STARTDATE, CONTRACT_ENDDATE, 
                                CONTRACT_TOTAL_FEES, CONTRACT_DEPOSIT_FEES, 
                                CLIENT_ID, CONTRACT_PAYMENT_TYPE)
        VALUES (104, 
                    TO_DATE('01.03.2021', 'DD.MM.YYYY'), TO_DATE('01.03.2024', 'DD.MM.YYYY'),
                    700000, NULL,
                    4, 'MONTHLY')
                    
    INTO CONTRACTS ( CONTRACT_ID, 
                                CONTRACT_STARTDATE, CONTRACT_ENDDATE, 
                                CONTRACT_TOTAL_FEES, CONTRACT_DEPOSIT_FEES, 
                                CLIENT_ID, CONTRACT_PAYMENT_TYPE)
        VALUES (105, 
                    TO_DATE('01.04.2021', 'DD.MM.YYYY'), TO_DATE('01.04.2026', 'DD.MM.YYYY'),
                    900000, 300000,
                    1, 'ANNUAL')
                    
    INTO CONTRACTS ( CONTRACT_ID, 
                                CONTRACT_STARTDATE, CONTRACT_ENDDATE, 
                                CONTRACT_TOTAL_FEES, CONTRACT_DEPOSIT_FEES, 
                                CLIENT_ID, CONTRACT_PAYMENT_TYPE)
        VALUES (106, 
                    TO_DATE('01.01.2021', 'DD.MM.YYYY'), TO_DATE('01.01.2026', 'DD.MM.YYYY'),
                    1000000, 200000,
                    3, 'HALF_ANNUAL')
SELECT * FROM DUAL;

--FILLING PAYMENTS_INSTALLMENTS_NO--
DECLARE
    CURSOR CONTRACTS_CRS IS
    SELECT CONTRACT_ID, CONTRACT_ENDDATE, CONTRACT_STARTDATE, CONTRACT_PAYMENT_TYPE
    FROM CONTRACTS;

    DIVISOR NUMBER(2);
    LOAN_DURATION NUMBER(6,2);
    RESULT NUMBER(5);
    
BEGIN
        FOR REC IN CONTRACTS_CRS LOOP
            
            IF REC.CONTRACT_PAYMENT_TYPE = 'MONTHLY' THEN
                DIVISOR := 1;
            ELSIF REC.CONTRACT_PAYMENT_TYPE = 'QUARTER' THEN
                DIVISOR := 3;
            ELSIF REC.CONTRACT_PAYMENT_TYPE = 'HALF_ANNUAL' THEN
                DIVISOR := 6;
            ELSIF REC.CONTRACT_PAYMENT_TYPE = 'ANNUAL' THEN
                DIVISOR := 12;
            END IF;
            
            LOAN_DURATION := MONTHS_BETWEEN(REC.CONTRACT_ENDDATE, REC.CONTRACT_STARTDATE);
            RESULT :=  LOAN_DURATION / DIVISOR;
            
            UPDATE CONTRACTS
            SET PAYMENTS_INSTALLMENTS_NO = RESULT
            WHERE CONTRACT_ID = REC.CONTRACT_ID;
        END LOOP;
END;

--CREATING SEQUENCE
CREATE SEQUENCE INST_PAID_SEQ
MINVALUE 1
MAXVALUE 9999999999
START WITH 1
INCREMENT BY 1;

--CREATING INSERT_INSTALL_TB PROCEDURE--
CREATE OR REPLACE PROCEDURE INSERT_INSTALL_TB (V_CONTRACT_ID NUMBER)
IS
            REC CONTRACTS%ROWTYPE;
            MONTHS_ADDED NUMBER(2);
            V_INSTALLMENT_DATE DATE;
            V_INSTALLMENT_AMOUNT NUMBER(20,2);
            
BEGIN
        SELECT *
        INTO REC
        FROM CONTRACTS
        WHERE CONTRACT_ID = V_CONTRACT_ID;
        
               IF REC.CONTRACT_PAYMENT_TYPE = 'MONTHLY' THEN
                MONTHS_ADDED := 1;
            ELSIF REC.CONTRACT_PAYMENT_TYPE = 'QUARTER' THEN
                MONTHS_ADDED := 3;
            ELSIF REC.CONTRACT_PAYMENT_TYPE = 'HALF_ANNUAL' THEN
                MONTHS_ADDED := 6;
            ELSIF REC.CONTRACT_PAYMENT_TYPE = 'ANNUAL' THEN
                MONTHS_ADDED := 12;
            END IF;     
            
                V_INSTALLMENT_AMOUNT := (REC.CONTRACT_TOTAL_FEES - NVL(REC.CONTRACT_DEPOSIT_FEES, 0)) / REC.PAYMENTS_INSTALLMENTS_NO;
                V_INSTALLMENT_DATE := REC.CONTRACT_STARTDATE;

        WHILE V_INSTALLMENT_DATE < REC.CONTRACT_ENDDATE LOOP
                INSERT INTO INSTALLMENTS_PAID ( INSTALLMENT_ID, CONTRACT_ID, INSTALLMENT_DATE, INSTALLMENT_AMOUNT)
                VALUES (INST_PAID_SEQ.NEXTVAL, V_CONTRACT_ID, V_INSTALLMENT_DATE, V_INSTALLMENT_AMOUNT);
                
                V_INSTALLMENT_DATE := ADD_MONTHS(V_INSTALLMENT_DATE, MONTHS_ADDED);
        END LOOP;

END;

--CALLING INSERT_INSTALL_TB PROCEDURE--
DECLARE
    CURSOR CONTRACTS_CRS IS
    SELECT *
    FROM CONTRACTS;

BEGIN
        FOR REC IN CONTRACTS_CRS LOOP
            INSERT_INSTALL_TB (REC.CONTRACT_ID);
        END LOOP;
                
END;
