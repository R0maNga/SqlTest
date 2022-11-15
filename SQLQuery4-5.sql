CREATE TABLE Town (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20)
	)

CREATE TABLE Filial (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20)
	)

CREATE TABLE Bank (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20)
	)

CREATE TABLE BankTownFilial (
	FilialId INT FOREIGN KEY REFERENCES Filial(id),
	TownId INT FOREIGN KEY REFERENCES Town(Id),
	BankId INT FOREIGN KEY REFERENCES Bank(Id) PRIMARY KEY (
		FilialId,
		TownId,
		BankId
		)
	)

CREATE TABLE SocialStatus (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20)
	)

CREATE TABLE Client (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20),
	SocialStatusId INT,
	CONSTRAINT FK_SocialStatus FOREIGN KEY (SocialStatusId) REFERENCES SocialStatus(Id)
	)

CREATE TABLE Account (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20),
	TotalBalance DECIMAL,
	ClientId INT FOREIGN KEY REFERENCES Client(Id),
	BankId INT,
	CONSTRAINT FK_BankId FOREIGN KEY (BankId) REFERENCES Bank(Id)
	)

CREATE TABLE PlasticCard (
	Id INT PRIMARY KEY,
	Name NVARCHAR(20),
	AccountId INT FOREIGN KEY REFERENCES Account(Id),
	Balance DECIMAL
	)

INSERT INTO Bank (id, name)
VALUES 
	('5', 'LSBank'),
	('1', 'PudgeBank'),
	('2', 'BitBank'),
	('3', 'RichBank'),
	('4', 'ErrorBank');

INSERT INTO Filial (id, name)
VALUES ('5', 'GOODFilial'),
	('1', 'BadFilial'),
	('2', 'PoorFilial'),
	('3', 'PudgeFilial'),
	('4', 'RichFilial');

INSERT INTO Town (id, name)
VALUES ('5', 'Ohaio'),
	('1', 'Minsk'),
	('2', 'Moscow'),
	('3', 'Tokyo'),
	('4', 'LA');

INSERT INTO BankTownFilial (BankId, TownId, FilialId)
VALUES ('5', '5', '5'),
	('1', '2', '1'),
	('3', '3','4'),
	('3', '4', '3'),
	('1', '2', '3'),
	('4', '2', '2');

INSERT INTO Client (id, name, SocialStatusId)
VALUES ('1', 'Person', '1'),
	('2', 'Unlucky', '2'),
	('3', 'Mask', '3'),
	('4', 'Who', '1'),
	('5', 'Deaf', '2')

INSERT INTO SocialStatus (id, name)
VALUES ('1', 'Junior'),
	('2', 'Disabled'),
	('3','Rich')

INSERT INTO Account (id, name, TotalBalance, ClientId, BankId)
VALUES ('1', 'Person', '300', '1', '1'),
	('2', 'Unlucky', '13', '2', '4'),
	('3', 'Mask', '1000', '3', '3'),
	('4', 'Who', '322', '4', '2'),
	('5', 'Mask', '1300', '1', '2')

INSERT INTO PlasticCard (id, name, AccountId, Balance)
VALUES ('1', 'VIP', '3', '200'),
	('2', 'Defolt', '1', '100'),
	('3', 'Big', '5', '300'),
	('4', 'Lucky', '2', '1'),
	('5', 'KO', '4', '228'),
	('6', 'Defolt2', '1', '200');

/* Покажи мне список банков 
у которых есть филиалы в городе X 
(выбери один из городов)*/


/* поиск по ID*/

SELECT DISTINCT Name
FROM Bank
RIGHT JOIN BankTownFilial ON Bank.id = BankTownFilial.BankId
WHERE BankId IN (
		SELECT BankId
		FROM BankTownFilial
		WHERE TownId = '2')

/* поиск по Имени города*/
SELECT DISTINCT Bank.name
FROM Bank
RIGHT JOIN BankTownFilial ON Bank.id = BankTownFilial.BankId
RIGHT JOIN Town ON BankTownFilial.TownId = Town.Id
WHERE Town.Name IN (
		SELECT Town.name
		FROM Town
		WHERE Town.Name = 'Moscow')


/*Получить список карточек 
с указанием имени владельца, 
баланса и названия банка*/

SELECT PlasticCard.Name, PlasticCard.Balance, Account.Name, Bank.name
FROM PlasticCard
LEFT JOIN Account ON Account.Id = PlasticCard.AccountId
LEFT JOIN Bank ON Bank.id = Account.BankId


/*
3. Показать список банковских аккаунтов 
у которых баланс не совпадает с суммой 
баланса по карточкам.
В отдельной колонке вывести разницу

*/

SELECT acc.Id, acc.Name, acc.TotalBalance, acc.ClientId, acc.BankId, acc.TotalBalance - SUM(lpc.Balance) AS diff
FROM Account AS acc
LEFT JOIN PlasticCard AS lpc ON lpc.AccountId = acc.Id
WHERE acc.TotalBalance != (
		SELECT SUM(pc.Balance)
		FROM PlasticCard AS pc
		WHERE pc.AccountId = acc.Id)
GROUP BY acc.Id, acc.Name, acc.TotalBalance, acc.ClientId, acc.BankId


/*
 Вывести кол-во банковских карточек 
 для каждого соц статуса 
 (2 реализации, GROUP BY и подзапросом)
*/

/*
Group BY
*/

SELECT ss.Name, COUNT(pc.Id) AS 'Number of card'
FROM SocialStatus AS ss
LEFT JOIN Client AS cl ON cl.SocialStatusId = ss.Id
INNER JOIN Account AS acc ON acc.ClientId = cl.Id
LEFT JOIN PlasticCard AS pc ON pc.AccountId = acc.Id
GROUP BY ss.Name




 

/*
 Получить список доступных средств для каждого клиента. 
 То есть если у клиента на банковском аккаунте 60 рублей, 
 и у него 2 карточки по 15 рублей на каждой, 
 то у него доступно 30 рублей для перевода на любую из карт

*/

SELECT cl.Name, acc.TotalBalance - SUM(lpc.Balance) AS FreeMoney
FROM Account AS acc
LEFT JOIN PlasticCard AS lpc ON lpc.AccountId = acc.Id
RIGHT JOIN Client AS cl ON acc.ClientId = cl.Id
WHERE acc.TotalBalance != (
			SELECT SUM(pc.Balance)
			FROM PlasticCard AS pc
			WHERE pc.AccountId = acc.Id)
		OR acc.TotalBalance = (
			SELECT SUM(pc.Balance)
			FROM PlasticCard AS pc
			WHERE pc.AccountId = acc.Id)
GROUP BY cl.Name, acc.TotalBalance
HAVING COUNT(cl.Name) = 1;

/*
Написать stored procedure которая будет добавлять по 10$ 
на каждый банковский аккаунт для определенного соц статуса 
(У каждого клиента бывают разные соц. статусы). 
Входной параметр процедуры - Id социального статуса. 
Обработать исключительные ситуации 
(например, был введен неверные номер соц. статуса. Либо когда у этого статуса нет привязанных аккаунтов).
*/

GO

 CREATE PROCEDURE SocialMoney1 (@SocialStatusId INT)
AS
BEGIN TRY
	UPDATE Account
	SET TotalBalance = TotalBalance + 10
	WHERE Account.ClientId IN (
			SELECT acc.ClientId
			FROM Account AS acc
			RIGHT JOIN Client AS cl ON acc.ClientId = cl.Id
			WHERE cl.SocialStatusId = @SocialStatusId)
END TRY

BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage
END CATCH

	/*
	7. Написать процедуру которая будет переводить определённую сумму со счёта
	на карту этого аккаунта.  При этом будем считать что деньги на счёту все равно останутся,
	просто сумма средств на карте увеличится. 
	Например, у меня есть аккаунт на котором 1000 рублей и две карты по 300 рублей на каждой.
	Я могу перевести 200 рублей на одну из карт, при этом баланс аккаунта останется 1000 рублей,
	а на картах будут суммы 300 и 500 рублей соответственно. 
	После этого я уже не смогу перевести 400 рублей с аккаунта ни на одну из карт, 
	так как останется всего 200 свободных рублей (1000-300-500). 
	Переводить БЕЗОПАСНО. То есть использовать транзакцию
	*/
GO

	CREATE PROCEDURE MoneyTransaction (@Money INT, @CardId INT)
AS
DECLARE @CardBalance INT
DECLARE @AccountBalance INT
BEGIN TRANSACTION 
	BEGIN TRY
		UPDATE PlasticCard
		SET Balance = Balance + @Money
		WHERE PlasticCard.Id = @CardId
		SAVE TRANSACTION a;

		IF(@@ERROR<>0)
		ROLLBACK TRANSACTION a;

		SELECT @CardBalance = SUM(PlasticCard.Balance)
		FROM PlasticCard
		Where PlasticCard.AccountId = @CardId
		SAVE TRANSACTION b;
		
		IF(@@ERROR<>0)
		ROLLBACK TRANSACTION b;

		Select @AccountBalance = Account.TotalBalance
		From Account
		Where Account.Id  IN (
		Select pc.AccountId
		From PlasticCard as pc 
		WHERE pc.AccountId = @CardId)

		IF (@CardBalance > @AccountBalance)
		ROLLBACK TRANSACTION
COMMIT	
END TRY

BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage
END CATCH

	/*
	Написать триггер на таблицы Account/Cards 
	чтобы нельзя была занести значения в поле баланс если это противоречит условиям  
	(то есть нельзя изменить значение в Account на меньшее, чем сумма балансов по всем карточкам. 
	И соответственно нельзя изменить баланс карты если в итоге сумма на картах будет больше чем баланс аккаунта)
	*/

GO

CREATE TRIGGER AccountCards_update25 ON Account
FOR UPDATE
AS
IF 
	UPDATE (TotalBalance)

DECLARE @Totalsum INT
DECLARE @TotalBalance INT
DECLARE @Id INT

SELECT @TotalBalance = inserted.TotalBalance, @Id = inserted.Id
FROM inserted

SELECT @TotalSum = sum(Balance)
FROM PlasticCard
WHERE @Id = AccountId

BEGIN
	IF (@TotalBalance < @Totalsum)
		ROLLBACK TRANSACTION

	PRINT 'Cannot set total balance less than Sum plastic Card Balance'
END



GO

CREATE TRIGGER Cards_update258 ON PlasticCard
FOR UPDATE
AS
IF 
	UPDATE (Balance)

DECLARE @Totalsum INT
DECLARE @AccountBalance INT
DECLARE @OldId INT

SELECT @OldId = d.AccountId
FROM deleted AS d

SELECT @TotalSum = sum(Balance)
FROM PlasticCard AS pc
WHERE pc.AccountId = @OldId

SELECT @AccountBalance = TotalBalance
FROM Account
WHERE Account.Id = @OldId

BEGIN
	IF (@Totalsum > @AccountBalance)
		ROLLBACK TRANSACTION

	PRINT 'Cannot set  Card balance more than total balance'
END

UPDATE Account
SET TotalBalance =  301 
Where Id = 1 

UPDATE PlasticCard
SET Balance =  10
Where Id = 2 

