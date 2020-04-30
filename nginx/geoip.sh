ipaddr=$1
mmdb_raw=$(mmdblookup --file /etc/td-agent-bit/nginx/GeoLite2-City.mmdb --ip "$ipaddr")

city_raw=$(echo "$mmdb_raw" | grep -A9 "\"city\":")
city=$(echo "$city_raw" | grep -A1 "\"en\":" | sed '$!d' | awk -F\" '{print $2}')

country_raw=$(echo "$mmdb_raw" | grep -A13 "\"country\":")
country_name=$(echo "$country_raw" | grep -A1 "\"en\":" | sed '$!d' | awk -F\" '{print $2}')
country_code=$(echo "$country_raw" | grep -A1 "\"iso_code\":" | sed '$!d' | awk -F\" '{print $2}')

latitude=$(echo "$mmdb_raw" | grep -A1 "\"latitude\":" | sed '$!d' | awk -F" <" '{print $1}' | xargs)
longitude=$(echo "$mmdb_raw" | grep -A1 "\"longitude\":" | sed '$!d' | awk -F" <" '{print $1}' | xargs)

region_raw=$(echo "$mmdb_raw" | grep -A12 "\"subdivisions\":")
region_name=$(echo "$region_raw" | grep -A1 "\"en\":" | sed '$!d' | awk -F\" '{print $2}')
region_code=$(echo "$region_raw" | grep -A1 "\"iso_code\":" | sed '$!d' | awk -F\" '{print $2}')

echo "city:$city"
echo "country_name:$country_name"
echo "country:$country_code"
echo "region_name:$region_name"
echo "region_code:$region_code"
echo "latitude:$latitude"
echo "longitude:$longitude"

