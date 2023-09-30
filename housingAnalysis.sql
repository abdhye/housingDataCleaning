select *
from HousingAnalysis..housingAnalysis


--standardizing date format
select SaleDate, convert(date, SaleDate)
from HousingAnalysis..housingAnalysis

update HousingAnalysis..housingAnalysis
set SaleDate = convert(date, SaleDate)

--above code didn't work, so tried the below
alter table HousingAnalysis..housingAnalysis
add SaleDateConverted date;

update HousingAnalysis..housingAnalysis
set SaleDateConverted = convert(date, SaleDate)

select SaleDateConverted
from HousingAnalysis..housingAnalysis


--populating property address
select *
from HousingAnalysis..housingAnalysis
where PropertyAddress is null
order by ParcelID

--same ParcelID has the same address, so we will use it to fill in the address
select tb_one.ParcelID, tb_one.PropertyAddress, tb_two.ParcelID, 
tb_two.PropertyAddress, isnull(tb_one.PropertyAddress, tb_two.PropertyAddress)
from HousingAnalysis..housingAnalysis tb_one
join HousingAnalysis..housingAnalysis tb_two
on tb_one.ParcelID = tb_two.ParcelID
and tb_one.[UniqueID ] <> tb_two.[UniqueID ]
where tb_one.PropertyAddress is null

update tb_one
set PropertyAddress = isnull(tb_one.PropertyAddress, tb_two.PropertyAddress)
from HousingAnalysis..housingAnalysis tb_one
join HousingAnalysis..housingAnalysis tb_two
on tb_one.ParcelID = tb_two.ParcelID
and tb_one.[UniqueID ] <> tb_two.[UniqueID ]
where tb_one.PropertyAddress is null


--splitting address into different columns (address, city, state)
--for PropertyAddress
select PropertyAddress
from HousingAnalysis..housingAnalysis

select 
substring(PropertyAddress, 1, charindex(',', PropertyAddress)-1) as Address,
substring(PropertyAddress, charindex(',', PropertyAddress)+1, len(PropertyAddress)) as city
from HousingAnalysis..housingAnalysis

alter table HousingAnalysis..housingAnalysis
add NewPropertyAddress nvarchar(255);

update HousingAnalysis..housingAnalysis
set NewPropertyAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress)-1)

alter table HousingAnalysis..housingAnalysis
add PropertyCity nvarchar(255);

update HousingAnalysis..housingAnalysis
set PropertyCity = substring(PropertyAddress, charindex(',', PropertyAddress)+1, len(PropertyAddress))

--for OwnerAddress
select OwnerAddress
from HousingAnalysis..housingAnalysis

select
parsename(replace(OwnerAddress,  ',', '.'), 3),
parsename(replace(OwnerAddress,  ',', '.'), 2),
parsename(replace(OwnerAddress,  ',', '.'), 1)
from HousingAnalysis..housingAnalysis

alter table HousingAnalysis..housingAnalysis
add NewOwnerAddress nvarchar(255);

update HousingAnalysis..housingAnalysis
set NewOwnerAddress = parsename(replace(OwnerAddress,  ',', '.'), 3)

alter table HousingAnalysis..housingAnalysis
add OwnerCity nvarchar(255);

update HousingAnalysis..housingAnalysis
set OwnerCity = parsename(replace(OwnerAddress,  ',', '.'), 2)

alter table HousingAnalysis..housingAnalysis
add OwnerSate nvarchar(255);

update HousingAnalysis..housingAnalysis
set OwnerSate = parsename(replace(OwnerAddress,  ',', '.'), 1)


--changing 'Y' and 'N' to 'Yes' and 'No'
select distinct(SoldAsVacant), count(SoldAsVacant)
from HousingAnalysis..housingAnalysis
group by SoldAsVacant
order by 2

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end
from HousingAnalysis..housingAnalysis

update HousingAnalysis..housingAnalysis
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
						end


--removing duplicates
with rowNumCTE as(
select *,
row_number() over(
partition by ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference
order by UniqueId
) rowNum
from HousingAnalysis..housingAnalysis
)
select *
from rowNumCTE
where rowNum > 1

with rowNumCTE as(
select *,
row_number() over(
partition by ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference
order by UniqueId
) rowNum
from HousingAnalysis..housingAnalysis
)
delete
from rowNumCTE
where rowNum > 1


--delete unused columns
alter table HousingAnalysis..housingAnalysis
drop column PropertyAddress, OwnerAddress, TaxDistrict, SaleDate
