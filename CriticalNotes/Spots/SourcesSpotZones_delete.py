from xml.dom import minidom

spot_surfaces_file = '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/spots_surfaces.txt'
spot_zones_file = '/Users/tbachmann/repos/opera/edition-74338567/resources/CN/spot_zones.xml'

# read surfaces
with open(spot_surfaces_file, mode ='r') as file:
    spot_surfaces = file.readlines()
    
    for i, surface in enumerate(spot_surfaces):
        spot_surfaces[i] = surface.strip()

# read zones
with open(spot_zones_file, mode ='r') as file:
    spot_zones = file.readlines()
    
    for i, zone in enumerate(spot_zones):
        spot_zones[i] = zone.strip()


# for spot in spot_zones:
#     print(spot)


# read sources
# TODO: read all source files in dir
source_files_path = '/Users/tbachmann/repos/opera/edition-74338567/sources/'
source_files = {
    'A': 'opera_source_af56ff93-664f-4df2-817c-5ad6d826e850.xml',
    'B': 'opera_source_c5eee823-cac3-40c6-b99f-7cde64ebee15.xml',
    'C': 'opera_source_5f7c64af-0aca-48b8-bb4f-8e5b5b1741ed.xml',
    'ME': 'opera_edition_me536d96-d5bf-422a-b155-4b8337ddf1me.xml'
}
sources = {}

for sigle, source in source_files.items():
    print(f'loading {sigle}: {source}')
    path = source_files_path + source
    # print('path: ', path)
    s = minidom.parse(source_files_path + source)
    # sources
    sources[sigle] = s

# add zones to respective surfaces
for sigle, source in sources.items():
    print(f'processing {sigle}: {source}')
    zones = source.getElementsByTagName('zone')
    for zone in zones:
        if zone.hasAttribute('type') and zone.getAttribute('type') == 'operaAnnotSpot':
            print('deleting zone:', zone.toxml())
            zone.parentNode.removeChild(zone)

# safe source files
for sigle, source in source_files.items():
    print(f'writing {sigle}: {source}')
    path = source_files_path + source
    with open(path, "w") as f: 
        f.write(sources[sigle].toxml())

# TODO: remove <?xml version="1.0" ?>
for sigle, source in source_files.items():
    print(f'removing empty lines in {sigle}: {source}')
    path = source_files_path + source
    lines = []
    with open(path, "r") as file: 
        lines = file.readlines()
        lines = [line.replace('<?xml version="1.0" ?>', '') for line in lines if line.strip() != '']
    with open(path, "w") as file: 
        file.writelines(lines)

