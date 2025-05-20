from xml.dom import minidom

# TODO: read spots/surfaces from CN xml-file

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

# check if number of surfaces and zones match
if len(spot_zones) != len(spot_surfaces):
    print('ERROR: number of surfaces and zones do not match')
    exit(1)

# merge surfaces and zones
surfaces_zones = []
for i in range(len(spot_surfaces)):
    surfaces_zones.append((spot_surfaces[i], spot_zones[i]))

# print('surfaces_zones:')
# for surface, zone in surfaces_zones:
#     print(f'{surface} -> {zone}')
# exit()

# for spot in spot_zones:
#     print(spot)


# read sources
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
    surfaces = source.getElementsByTagName('surface')
    for surface in surfaces:
        if surface.hasAttribute('xml:id'):
            this_id = surface.getAttribute('xml:id')
            # print(this_id)
            for surface_zone in surfaces_zones:
                surface_id, spot_zones = surface_zone
                # print(f'surface_id: {surface_id}, this_id: {this_id}')
                if this_id == surface_id:
                    print(f'found {this_id}, deleting')
                    # surface.createElement('zone')
                    zone = minidom.parseString(spot_zones)
                    surface.appendChild(zone.documentElement)
                    # print(zone)


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
        lines = [line.replace('<?xml version="1.0" ?>', '') for line in lines]
    with open(path, "w") as file: 
        file.writelines(lines)
