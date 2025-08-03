CREATE DATABASE AmazonWebServices;

USE AmazonWebServices;


CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    CreatedDateTime DATETIME
);

CREATE TABLE UserAddresses (
    AddressId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    StreetAddress NVARCHAR(100) NOT NULL,
    City NVARCHAR(50),
    StateProvince NVARCHAR(50),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(50),
    CONSTRAINT FK_UserAddresses_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE TABLE ShippingZones (
    ShippingZoneId INT PRIMARY KEY IDENTITY(1,1),
    ZoneName NVARCHAR(50) NOT NULL,
    RegionName NVARCHAR(100)
);

CREATE TABLE ProductCategories (
    CategoryId INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL
);

CREATE TABLE Products (
    ProductId INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CategoryId INT NOT NULL,
    StockQuantity INT NOT NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES ProductCategories(CategoryId)
);

CREATE TABLE Orders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    OrderDateTime DATETIME,
    ShippingAddressId INT NOT NULL,
    ShippingZoneId INT NOT NULL,
    OrderStatus NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_Orders_Addresses FOREIGN KEY (ShippingAddressId) REFERENCES UserAddresses(AddressId),
    CONSTRAINT FK_Orders_ShippingZones FOREIGN KEY (ShippingZoneId) REFERENCES ShippingZones(ShippingZoneId)
);

CREATE TABLE OrderItems (
    OrderItemId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

CREATE TABLE Packages (
    PackageId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT NOT NULL,
    PackageStatus NVARCHAR(50) NOT NULL,
    ShippedDateTime DATETIME,
    DeliveredDateTime DATETIME,
    CONSTRAINT FK_Packages_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
);

CREATE TABLE Deliveries (
    DeliveryId INT PRIMARY KEY IDENTITY(1,1),
    PackageId INT NOT NULL,
    DeliveryMethod NVARCHAR(50) NOT NULL,
    TrackingNumber NVARCHAR(100),
    EstimatedDeliveryDate DATE,
    CONSTRAINT FK_Deliveries_Packages FOREIGN KEY (PackageId) REFERENCES Packages(PackageId)
);

CREATE TABLE PaymentMethods (
    PaymentMethodId INT PRIMARY KEY IDENTITY(1,1),
    UserId INT NOT NULL,
    PaymentType NVARCHAR(50) NOT NULL,
    CreatedDateTime DATETIME, 
    CONSTRAINT FK_PaymentMethods_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE TABLE AmazonPayAccounts (
    AmazonPayAccountId INT PRIMARY KEY IDENTITY(1,1),
    PaymentMethodId INT NOT NULL,
    AmazonEmail NVARCHAR(100) NOT NULL,
    LinkedDateTime DATETIME,
    CONSTRAINT FK_AmazonPayAccounts_PaymentMethods FOREIGN KEY (PaymentMethodId) REFERENCES PaymentMethods(PaymentMethodId)
);

CREATE TABLE Payments (
    PaymentId INT IDENTITY PRIMARY KEY,
    OrderId INT NOT NULL,
    PaymentMethod VARCHAR(20) NOT NULL,
    PaymentStatus VARCHAR(20) NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentDateTime DATETIME NOT NULL,
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
    CONSTRAINT CHK_PaymentMethod CHECK (PaymentMethod IN ('CreditCard', 'DebitCard', 'PayPal', 'AmazonPay')),
    CONSTRAINT CHK_PaymentStatus CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded'))
);




