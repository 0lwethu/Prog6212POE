-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

IF DB_ID('RaceDay') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
END;
GO

CREATE DATABASE RaceDay;
GO

USE RaceDay;
GO


-- ============================================================
-- 2. CREATE USER TABLE
-- ============================================================

CREATE TABLE [User]
(
    UserID INT IDENTITY(1,1) NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL,
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_User_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_User
        PRIMARY KEY (UserID),

    CONSTRAINT UQ_User_Email
        UNIQUE (Email),

    CONSTRAINT CK_User_Role
        CHECK (Role IN ('Participant', 'Organiser'))
);
GO


-- ============================================================
-- 3. CREATE PARTICIPANT TABLE
-- ============================================================

CREATE TABLE Participant
(
    ParticipantID INT IDENTITY(1,1) NOT NULL,
    UserID INT NOT NULL,
    IDNumber VARCHAR(20) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    EmergencyContactName VARCHAR(100) NOT NULL,
    EmergencyContactPhone VARCHAR(20) NOT NULL,

    CONSTRAINT PK_Participant
        PRIMARY KEY (ParticipantID),

    CONSTRAINT UQ_Participant_UserID
        UNIQUE (UserID),

    CONSTRAINT UQ_Participant_IDNumber
        UNIQUE (IDNumber),

    CONSTRAINT FK_Participant_User
        FOREIGN KEY (UserID)
        REFERENCES [User](UserID)
);
GO


-- ============================================================
-- 4. CREATE ORGANISER TABLE
-- ============================================================

CREATE TABLE Organiser
(
    OrganiserID INT IDENTITY(1,1) NOT NULL,
    UserID INT NOT NULL,
    OrganisationName VARCHAR(150) NOT NULL,
    Phone VARCHAR(20) NOT NULL,

    CONSTRAINT PK_Organiser
        PRIMARY KEY (OrganiserID),

    CONSTRAINT UQ_Organiser_UserID
        UNIQUE (UserID),

    CONSTRAINT FK_Organiser_User
        FOREIGN KEY (UserID)
        REFERENCES [User](UserID)
);
GO


-- ============================================================
-- 5. CREATE EVENT TABLE
-- ============================================================

CREATE TABLE Event
(
    EventID INT IDENTITY(1,1) NOT NULL,
    OrganiserID INT NOT NULL,
    EventName VARCHAR(150) NOT NULL,
    Description VARCHAR(500) NULL,
    EventDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    Location VARCHAR(200) NOT NULL,
    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Event_Status DEFAULT 'Upcoming',
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Event_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Event
        PRIMARY KEY (EventID),

    CONSTRAINT FK_Event_Organiser
        FOREIGN KEY (OrganiserID)
        REFERENCES Organiser(OrganiserID),

    CONSTRAINT CK_Event_Status
        CHECK (Status IN ('Upcoming', 'Open', 'Closed', 'Completed', 'Cancelled'))
);
GO


-- ============================================================
-- 6. CREATE CATEGORY TABLE
-- ============================================================

CREATE TABLE Category
(
    CategoryID INT IDENTITY(1,1) NOT NULL,
    EventID INT NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    DistanceKm DECIMAL(5,2) NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL,
    MaxParticipants INT NOT NULL,

    CONSTRAINT PK_Category
        PRIMARY KEY (CategoryID),

    CONSTRAINT FK_Category_Event
        FOREIGN KEY (EventID)
        REFERENCES Event(EventID),

    CONSTRAINT UQ_Category_Event_Name
        UNIQUE (EventID, CategoryName),

    CONSTRAINT CK_Category_Distance
        CHECK (DistanceKm > 0),

    CONSTRAINT CK_Category_EntryFee
        CHECK (EntryFee >= 0),

    CONSTRAINT CK_Category_MaxParticipants
        CHECK (MaxParticipants > 0)
);
GO


-- ============================================================
-- 7. CREATE ROUTE TABLE
-- ============================================================

CREATE TABLE Route
(
    RouteID INT IDENTITY(1,1) NOT NULL,
    EventID INT NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    ElevationGainM INT NOT NULL,
    StartPoint VARCHAR(200) NOT NULL,
    FinishPoint VARCHAR(200) NOT NULL,
    RouteUrl VARCHAR(500) NULL,

    CONSTRAINT PK_Route
        PRIMARY KEY (RouteID),

    CONSTRAINT UQ_Route_EventID
        UNIQUE (EventID),

    CONSTRAINT FK_Route_Event
        FOREIGN KEY (EventID)
        REFERENCES Event(EventID),

    CONSTRAINT CK_Route_Distance
        CHECK (DistanceKm > 0),

    CONSTRAINT CK_Route_Elevation
        CHECK (ElevationGainM >= 0)
);
GO


-- ============================================================
-- 8. CREATE ENROLLMENT TABLE
-- ============================================================

CREATE TABLE Enrollment
(
    EnrollmentID INT IDENTITY(1,1) NOT NULL,
    ParticipantID INT NOT NULL,
    CategoryID INT NOT NULL,
    EnrollmentDate DATETIME2 NOT NULL
        CONSTRAINT DF_Enrollment_Date DEFAULT SYSDATETIME(),
    RaceNumber VARCHAR(20) NOT NULL,
    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Enrollment_Status DEFAULT 'Confirmed',

    CONSTRAINT PK_Enrollment
        PRIMARY KEY (EnrollmentID),

    CONSTRAINT FK_Enrollment_Participant
        FOREIGN KEY (ParticipantID)
        REFERENCES Participant(ParticipantID),

    CONSTRAINT FK_Enrollment_Category
        FOREIGN KEY (CategoryID)
        REFERENCES Category(CategoryID),

    CONSTRAINT UQ_Enrollment_RaceNumber
        UNIQUE (RaceNumber),

    CONSTRAINT UQ_Enrollment_Participant_Category
        UNIQUE (ParticipantID, CategoryID),

    CONSTRAINT CK_Enrollment_Status
        CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled'))
);
GO


-- ============================================================
-- 9. CREATE RESULT TABLE
-- ============================================================

CREATE TABLE Result
(
    ResultID INT IDENTITY(1,1) NOT NULL,
    EnrollmentID INT NOT NULL,
    FinishTime TIME NOT NULL,
    Position INT NOT NULL,
    ResultStatus VARCHAR(20) NOT NULL
        CONSTRAINT DF_Result_Status DEFAULT 'Finished',
    RecordedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Result_RecordedAt DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Result
        PRIMARY KEY (ResultID),

    CONSTRAINT UQ_Result_EnrollmentID
        UNIQUE (EnrollmentID),

    CONSTRAINT FK_Result_Enrollment
        FOREIGN KEY (EnrollmentID)
        REFERENCES Enrollment(EnrollmentID),

    CONSTRAINT CK_Result_Position
        CHECK (Position > 0),

    CONSTRAINT CK_Result_Status
        CHECK (ResultStatus IN ('Finished', 'DNF', 'DNS', 'Disqualified'))
);
GO


-- ============================================================
-- 10. INSERT USERS
-- ============================================================

INSERT INTO [User]
    (FirstName, LastName, Email, PasswordHash, Role)
VALUES
    ('Thabo', 'Mokoena', 'thabo.mokoena@raceday.co.za',
     'HASHED_PASSWORD_001', 'Participant'),

    ('Lerato', 'Dlamini', 'lerato.dlamini@raceday.co.za',
     'HASHED_PASSWORD_002', 'Participant'),

    ('Sipho', 'Naidoo', 'sipho.naidoo@raceday.co.za',
     'HASHED_PASSWORD_003', 'Organiser'),

    ('Ayesha', 'Peters', 'ayesha.peters@raceday.co.za',
     'HASHED_PASSWORD_004', 'Organiser');
GO


-- ============================================================
-- 11. INSERT PARTICIPANTS
-- ============================================================

INSERT INTO Participant
    (UserID, IDNumber, Phone, EmergencyContactName, EmergencyContactPhone)
VALUES
    (1, '9001015001088', '0825551001',
     'Mandla Mokoena', '0825552001'),

    (2, '9505056002089', '0835551002',
     'Nomsa Dlamini', '0835552002');
GO


-- ============================================================
-- 12. INSERT ORGANISERS
-- ============================================================

INSERT INTO Organiser
    (UserID, OrganisationName, Phone)
VALUES
    (3, 'Cape Road Events', '0115553001'),

    (4, 'South African Road Sports', '0215553002');
GO


-- ============================================================
-- 13. INSERT EVENTS
-- ============================================================

INSERT INTO Event
    (OrganiserID, EventName, Description, EventDate,
     StartTime, Location, Status)
VALUES
    (
        1,
        'Johannesburg Spring Run',
        'A community road running event in Johannesburg.',
        '2026-10-18',
        '06:30',
        'Johannesburg, Gauteng',
        'Open'
    ),

    (
        1,
        'Cape Town Coastal Cycle',
        'A scenic cycling event along the Cape Town coastline.',
        '2026-11-08',
        '06:00',
        'Cape Town, Western Cape',
        'Open'
    ),

    (
        2,
        'Durban Summer Marathon',
        'A road running marathon event in Durban.',
        '2027-01-24',
        '05:30',
        'Durban, KwaZulu-Natal',
        'Upcoming'
    );
GO


-- ============================================================
-- 14. INSERT CATEGORIES
-- Each event has multiple categories
-- ============================================================

-- Johannesburg Spring Run - EventID 1

INSERT INTO Category
    (EventID, CategoryName, DistanceKm, EntryFee, MaxParticipants)
VALUES
    (1, '5 KM Fun Run', 5.00, 80.00, 1000),
    (1, '10 KM Road Race', 10.00, 150.00, 1500),
    (1, '21.1 KM Half Marathon', 21.10, 250.00, 1200);


-- Cape Town Coastal Cycle - EventID 2

INSERT INTO Category
    (EventID, CategoryName, DistanceKm, EntryFee, MaxParticipants)
VALUES
    (2, '20 KM Cycle', 20.00, 180.00, 800),
    (2, '40 KM Cycle', 40.00, 280.00, 1000),
    (2, '80 KM Cycle', 80.00, 450.00, 700);


-- Durban Summer Marathon - EventID 3

INSERT INTO Category
    (EventID, CategoryName, DistanceKm, EntryFee, MaxParticipants)
VALUES
    (3, '10 KM Run', 10.00, 150.00, 1500),
    (3, '21.1 KM Half Marathon', 21.10, 250.00, 1200),
    (3, '42.2 KM Marathon', 42.20, 350.00, 1000);
GO


-- ============================================================
-- 15. INSERT ROUTES
-- One route per event
-- ============================================================

INSERT INTO Route
    (EventID, DistanceKm, ElevationGainM,
     StartPoint, FinishPoint, RouteUrl)
VALUES
    (
        1,
        21.10,
        210,
        'Zoo Lake, Johannesburg',
        'Zoo Lake, Johannesburg',
        'https://raceday.example/routes/johannesburg-spring'
    ),

    (
        2,
        80.00,
        650,
        'Cape Town Stadium',
        'Cape Town Stadium',
        'https://raceday.example/routes/cape-town-coastal'
    ),

    (
        3,
        42.20,
        380,
        'Durban Moses Mabhida Stadium',
        'Durban Moses Mabhida Stadium',
        'https://raceday.example/routes/durban-marathon'
    );
GO


-- ============================================================
-- 16. INSERT ENROLLMENTS
-- ============================================================

INSERT INTO Enrollment
    (ParticipantID, CategoryID, EnrollmentDate, RaceNumber, Status)
VALUES
    (
        1,
        2,
        '2026-09-01 09:15:00',
        'RD-0001',
        'Confirmed'
    ),

    (
        2,
        3,
        '2026-09-01 10:30:00',
        'RD-0002',
        'Confirmed'
    ),

    (
        1,
        4,
        '2026-09-02 08:45:00',
        'RD-0003',
        'Confirmed'
    ),

    (
        2,
        7,
        '2026-09-02 11:20:00',
        'RD-0004',
        'Confirmed'
    );
GO


-- ============================================================
-- 17. INSERT SAMPLE RESULTS
-- Results are linked to completed/recorded enrolments
-- ============================================================

INSERT INTO Result
    (EnrollmentID, FinishTime, Position, ResultStatus)
VALUES
    (
        1,
        '00:52:35',
        24,
        'Finished'
    ),

    (
        2,
        '01:58:42',
        37,
        'Finished'
    );
GO


-- ============================================================
-- 18. TEST / DISPLAY THE DATA
-- ============================================================

SELECT * FROM [User];

SELECT * FROM Participant;

SELECT * FROM Organiser;

SELECT * FROM Event;

SELECT * FROM Category;

SELECT * FROM Route;

SELECT * FROM Enrollment;

SELECT * FROM Result;
GO


-- ============================================================
-- 19. USEFUL JOIN QUERY
-- Shows participants, events, categories and results
-- ============================================================

SELECT
    e.EnrollmentID,
    u.FirstName + ' ' + u.LastName AS ParticipantName,
    ev.EventName,
    c.CategoryName,
    c.DistanceKm,
    e.RaceNumber,
    e.Status AS EnrollmentStatus,
    r.FinishTime,
    r.Position,
    r.ResultStatus
FROM Enrollment e
INNER JOIN Participant p
    ON e.ParticipantID = p.ParticipantID
INNER JOIN [User] u
    ON p.UserID = u.UserID
INNER JOIN Category c
    ON e.CategoryID = c.CategoryID
INNER JOIN Event ev
    ON c.EventID = ev.EventID
LEFT JOIN Result r
    ON e.EnrollmentID = r.EnrollmentID
ORDER BY ev.EventDate, e.RaceNumber;
GO