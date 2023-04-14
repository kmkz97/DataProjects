Select *
FROM NashvilleHousingData

-- Fixing Missing values in Property address data

SELECT *
FROM NashvilleHousingData
WHERE PropertyAddress IS NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningProject..NashvilleHousingData a
JOIN DataCleaningProject..NashvilleHousingData b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningProject..NashvilleHousingData a
JOIN DataCleaningProject..NashvilleHousingData b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

---------------------------------------------------------------------
-- Breaking out PropertyAddress into address, city and OwnerAddress into address, city and state

SELECT PropertyAddress
FROM NashvilleHousingData

SELECT
	SUBSTRING (PropertyAddress, 1 , CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)) AS City
FROM NashvilleHousingData

-- Making sure city names came out alright
SELECT Distinct(SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))) AS City
FROM NashvilleHousingData

With CityNames
as
(
SELECT SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)) AS City
FROM NashvilleHousingData
)
SELECT City, COUNT(City) AS CountOfCity
FROM CityNames
GROUP BY City
ORDER BY CountOfCity DESC


ALTER TABLE NashvilleHousingData
Add PropertyStreetAddress NVARCHAR(100)

UPDATE NashvilleHousingData
SET PropertyStreetAddress = SUBSTRING (PropertyAddress, 1 , CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousingData
Add PropertyCity NVARCHAR(100)

UPDATE NashvilleHousingData
SET PropertyCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))

SELECT OwnerAddress
FROM NashvilleHousingData

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousingData

ALTER TABLE NashvilleHousingData
ADD
OwnerStreetAddress NVARCHAR(100),
OwnerCity NVARCHAR(100),
OwnerState NVARCHAR(100)

UPDATE NashvilleHousingData
SET 
	OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


----------------------------------------------------------------------------------
-- Creating a yes no field for the sold as vacant variable

ALTER TABLE NashvilleHousingData
ADD VacantYesNo NVARCHAR(100)

UPDATE NashvilleHousingData
SET VacantYesNo = CASE
	WHEN SoldAsVacant = '0' THEN 'No'
	WHEN SoldAsVacant = '1' THEN 'Yes'
	ELSE SoldAsVacant
	END

SELECT DISTINCT(VacantYesNo), COUNT(VacantYesNo)
FROM NashvilleHousingData
GROUP BY VacantYesNo

------------------------------------------------------------
-- Remove Duplicates

With RowNumCTE as
(
SELECT *,
	Row_number() OVER (
	PARTITION BY	ParcelID,
					PropertyAddress,
					SaleDate,
					SalePrice,
					LegalReference
					ORDER BY
						UniqueID
						) row_num
FROM NashvilleHousingData
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

---------------------------------------------------------------------------
-- Deleting Unused Columns

ALTER TABLE NashvilleHousingData
DROP COLUMN SoldAsVacant, OwnerAddress, TaxDistrict, PropertyAddress 

SELECT *
FROM NashvilleHousingData