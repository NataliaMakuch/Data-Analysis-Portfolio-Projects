-- Based on Portfolio Project from Alex the Analyst YouTube channel
-- https://youtu.be/8rO7ztF4NtU

SELECT * 
FROM Project..Housing_Nashville

----------------------------------------

-- Populate Property Address 

SELECT ParcelID, PropertyAddress, UniqueID
FROM Project..Housing_Nashville
WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT Tab1.ParcelID, Tab1.PropertyAddress, Tab2.ParcelID, Tab2.PropertyAddress, ISNULL(Tab1.PropertyAddress, Tab2.PropertyAddress)
FROM Project..Housing_Nashville Tab1
JOIN Project..Housing_Nashville Tab2
	ON Tab1.ParcelID = Tab2.ParcelID
	AND Tab1.UniqueID <> Tab2.[UniqueID ]
WHERE Tab1.PropertyAddress is null

UPDATE Tab1
SET PropertyAddress = ISNULL(Tab1.PropertyAddress, Tab2.PropertyAddress)
FROM Project..Housing_Nashville Tab1
JOIN Project..Housing_Nashville Tab2
	ON Tab1.ParcelID = Tab2.ParcelID
	AND Tab1.UniqueID <> Tab2.[UniqueID ]
----------------------------------------

-- Split Address into separate columns

-- Split Property Address using Substring

SELECT PropertyAddress,
		SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as PropertyAddress_Address,
		SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as PropertyAddress_City
FROM Project..Housing_Nashville

ALTER TABLE Project..Housing_Nashville
ADD PropertyAddress_Address Nvarchar(255)

ALTER TABLE Project..Housing_Nashville
ADD PropertyAddress_City Nvarchar(255)

UPDATE Project..Housing_Nashville
SET PropertyAddress_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
	PropertyAddress_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- Split Owner Address using Purse

SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as OwnerAddress_Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as OwnerAddress_City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as OwnerAddress_State
FROM Project..Housing_Nashville

ALTER TABLE Project..Housing_Nashville
ADD OwnerAddress_Address Nvarchar(255)

ALTER TABLE Project..Housing_Nashville
ADD OwnerAddress_City Nvarchar(255)

ALTER TABLE Project..Housing_Nashville
ADD OwnerAddress_State Nvarchar(255)

SELECT *
FROM Project..Housing_Nashville

UPDATE Project..Housing_Nashville
SET OwnerAddress_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerAddress_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerAddress_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM Project..Housing_Nashville

---------------------------------------

-- SaleDate format change 

SELECT SaleDate	
FROM Project..Housing_Nashville

ALTER TABLE Project..Housing_Nashville
ADD SaleDate_Standardized Date

SELECT *
FROM Project..Housing_Nashville

UPDATE Project..Housing_Nashville
SET SaleDate_Standardized = CONVERT(Date, SaleDate)

---------------------------------------

-- Change 'Y' and 'N' to 'Yes' and 'No' > SoldAsVacant

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM Project..Housing_Nashville
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM Project..Housing_Nashville

UPDATE Project..Housing_Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END

---------------------------------------

-- Delete Unused Columns

SELECT *
FROM Project..Housing_Nashville

ALTER TABLE Project..Housing_Nashville
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

---------------------------------------

-- Remove Duplicates

-- Deleting from dataset

WITH RowNum AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress_Address,
				 PropertyAddress_City,
				 SalePrice,
				 SaleDate_Standardized,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM Project..Housing_Nashville
--ORDER BY ParcelID
)

DELETE
FROM RowNum
WHERE row_num > 1

--Checking

WITH RowNum AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress_Address,
				 PropertyAddress_City,
				 SalePrice,
				 SaleDate_Standardized,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM Project..Housing_Nashville
--ORDER BY ParcelID
)

SELECT *
FROM RowNum
WHERE row_num > 1
ORDER BY PropertyAddress_Address

---------------------------------------

SELECT *
FROM Project..Housing_Nashville
