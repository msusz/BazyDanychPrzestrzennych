create extension postgis
create extension postgis_raster

-- zad 3
-- select st_union(rast) from uk_250k
-- nie dziala, poniewaz rozmiar wynikowy przekracza limit postgresa (1GB dla pojedynczej wartosci)

-- zad 6
update national_parks
set geom = st_setsrid(geom, 27700);


create table uk_lake_district as (select st_union(st_clip(rast, geom)) as rast
                                  from uk_250k u
                                           inner join national_parks np on st_intersects(geom, rast)
                                  where np.gid = 1);


-- zad 7
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
                     ST_AsGDALRaster(rast, 'GTiff', ARRAY ['COMPRESS=DEFLATE',
                         'PREDICTOR=2', 'PZLEVEL=9'])
           ) AS loid
FROM uk_lake_district;
----------------------------------------------
SELECT lo_export(loid, 'G:\myraster.tiff')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;


-- zad 10

CREATE TABLE uk_lake_ndvi AS
WITH r AS (select st_clip(rast, st_transform(geom,32630)) as rast
                                  from sentinel u
                                           inner join national_parks np on st_intersects(st_transform(geom,32630), rast)
                                  where np.gid = 1)
SELECT
       ST_MapAlgebra(
               r.rast, 1,
               r.rast, 4,
               '([rast2.val] - [rast1.val]) / ([rast2.val] +
               [rast1.val])::float', '32BF'
           ) AS rast
FROM r;

-- zad 11
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
                     ST_AsGDALRaster(st_union(rast), 'GTiff', ARRAY ['COMPRESS=DEFLATE',
                         'PREDICTOR=2', 'PZLEVEL=9'])
           ) AS loid
FROM uk_lake_ndvi;

-- st_union nie dziala: [XX000] ERROR: rt_raster_from_two_rasters: The two rasters provided do not have the same alignment
----------------------------------------------
SELECT lo_export(loid, 'G:\myraster.tiff')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;

