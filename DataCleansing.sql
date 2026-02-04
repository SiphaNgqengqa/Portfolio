--##########################################################################
--	AUTHOR: SANELISO MZWAKALI
--	LAST UPDATE: 12/11/2021
--	DESCRIPTION: Nashville data Cleansing Project
--	SERVER NAME: 
--	DATABASE NAME: DataCleansing
--##########################################################################

	USE [DataCleansing]
	SET LANGUAGE BRITISH

	---------------------------------------------
	-- TRANSFER DATA FROM RAW TO WIP(Work in Progress)
	----------------------------------------------

	drop table [WIP].[NashvilleData]

	--Error: The specified schema name "WIP" either does not exist or you do not have permission to use it.
	--Solution: CREATE SCHEMA WIP
	
	SELECT *
	INTO [WIP].[NashvilleData]
	FROM [RAW].[NashvilleData]
	--(56477 row(s) affected)


	-----------------------------------------------------------------------
	--STANDARDIZE DATA FORMAT
	-----------------------------------------------------------------------
	SELECT * FROM [WIP].[NashvilleData]

	--CREATE NEW DATE COLUMN
	ALTER TABLE [WIP].[NashvilleData]
	ADD NewSaleDate varchar(10)


	SELECT SaleDate, CONVERT(VARCHAR(10), SaleDate, 103), CONVERT(VARCHAR(103),
	CAST(CONVERT(CHAR(11), SaleDate, 113) as date))
	FROM [WIP].[NashvilleData]
	-- Before: 2014-12-12 00:00:00.000


	UPDATE [WIP].[NashvilleData]
	SET NewSaleDate =  CONVERT(VARCHAR(10), SaleDate, 103)
	WHERE [UniqueID ] = [UniqueID ]
	-- After: 12/12/2014

	--(56477 row(s) affected)

	SELECT * FROM [WIP].[NashvilleData]


	--Alter column data type
	ALTER TABLE [WIP].[NashvilleData]
	ALTER COLUMN SaleDate varchar(10)

	--Update with new date format.
	UPDATE [WIP].[NashvilleData]
	SET SaleDate =  NewSaleDate

	--DROP COLUMN
	ALTER TABLE [WIP].[NashvilleData]
	DROP COLUMN NewSaleDate


	-----------------------------------------------------------------------
	--POPULATE PROPERTY ADDRESS DATA
	-----------------------------------------------------------------------
	SELECT * 
	FROM [WIP].[NashvilleData]
	where PropertyAddress is null
	ORDER BY ParcelID

	SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
	FROM [WIP].[NashvilleData] A
	JOIN [WIP].[NashvilleData] B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
	WHERE A.PropertyAddress IS NULL


	--(35 row(s) So we have to address all of these - THE ISNULL part is what im going to take and put it in the null rows)

	UPDATE A
	SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
	FROM [WIP].[NashvilleData] A
	JOIN [WIP].[NashvilleData] B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
	WHERE A.PropertyAddress IS NULL
	--(29 row(s) affected)



	-----------------------------------------------------------------------
	--BREAKING OUT ADDRESS INT INDIVIDUAL COLUMS (ADDRESS, CITY, STATE)
	-----------------------------------------------------------------------
	SELECT PropertyAddress
	FROM [WIP].[NashvilleData]
	--where PropertyAddress is null
	--ORDER BY ParcelID

	SELECT 
	SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) -1 ) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+ 1, LEN(PropertyAddress)) AS Address
	FROM [WIP].[NashvilleData]



	ALTER TABLE [WIP].[NashvilleData]
	ADD  PropertySplitAddress Nvarchar(255)
	
	UPDATE [WIP].[NashvilleData]
	SET PropertySplitAddress =  SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) -1 )
	--(56477 row(s) affected)

	
	ALTER TABLE [WIP].[NashvilleData]
	ADD PropertySplitCity Nvarchar(255)

	UPDATE [WIP].[NashvilleData]
	SET PropertySplitCity =  SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+ 1, LEN(PropertyAddress))
	--(56477 row(s) affected)



	SELECT * 
	FROM [WIP].[NashvilleData]


	SELECT OwnerAddress
	FROM [WIP].[NashvilleData]

	SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
	FROM [WIP].[NashvilleData]


	ALTER TABLE [WIP].[NashvilleData]
	ADD  OwnerSplitAddress Nvarchar(255)
	
	UPDATE [WIP].[NashvilleData]
	SET OwnerSplitAddress =  PARSENAME(REPLACE(OwnerAddress,',','.'),3)
	--(56477 row(s) affected)

	
	ALTER TABLE [WIP].[NashvilleData]
	ADD OwnerSplitCity Nvarchar(255)

	UPDATE [WIP].[NashvilleData]
	SET OwnerSplitCity =  PARSENAME(REPLACE(OwnerAddress,',','.'),2)
	--(56477 row(s) affected)


	ALTER TABLE [WIP].[NashvilleData]
	ADD OwnerSplitState Nvarchar(255)

	UPDATE [WIP].[NashvilleData]
	SET OwnerSplitState =  PARSENAME(REPLACE(OwnerAddress,',','.'),1)
	--(56477 row(s) affected)





	-----------------------------------------------------------------------
	--CHANGE Y AND N TO YES AND NO IN "SOLID AS VACANT" FIELD
	-----------------------------------------------------------------------
	SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
	FROM [WIP].[NashvilleData]
	GROUP BY SoldAsVacant
	ORDER BY 2


	SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
	FROM [WIP].[NashvilleData]


	UPDATE [WIP].[NashvilleData]
	SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
	--(56477 row(s) affected)


	-----------------------------------------------------------------------
	--REMOVE DUPLICATES
	-----------------------------------------------------------------------
	WITH RowNumCTE AS(
	SELECT *, 
	ROW_NUMBER() OVER (PARTITION BY [ParcelID],
									[PropertyAddress],
									[SalePrice],
									[SaleDate],
									[LegalReference]
									ORDER BY 
									[UniqueID]) row_num
									
	FROM [WIP].[NashvilleData]
	--ORDER BY ParcelID
	)
	DELETE
	FROM RowNumCTE
	WHERE row_num > 1
	--ORDER BY PropertyAddress
	--(104 row(s) affected)


	-----------------------------------------------------------------------
	--DELETE UNUSED COLUMNS
	-----------------------------------------------------------------------

	SELECT * 
	FROM [WIP].[NashvilleData]

	ALTER TABLE [WIP].[NashvilleData]
	DROP COLUMN [OwnerAddress],[TaxDistrict],[PropertyAddress]


