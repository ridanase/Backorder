#! /bin/sh


######################################################################
# This function print the status of the orderID from the backorder.  #
######################################################################
function process_single_orderID () {

   #*****   Get the authorized token  *****
   autrorizationXML=`curl -H "Authorization: Basic dDd6d21xenQ4cGJuczRucW10YzljcjN1Oll1VVhYWTdHUTNXREhBeFdxZ2g5elNKeg==" \
                          -H "Accept: application/json" \
                          -H "Content-Type: application/x-www-form-urlencoded" \
                          -d 'grant_type=client_credentials' \
                          -X POST https://auth.shopatron.com/oauthserver/oauth2/token`

   access_token=`echo "$autrorizationXML" | \
                      python -c 'import sys, json; print json.load(sys.stdin)["access_token"]'`

   #*****  Get the Backorder Total Count *****
   orderStatus=`curl -H "Content-Type: application/json" \
                     -H "Authorization: Bearer $access_token" \
                     -H "API-Key: t7zwmqzt8pbns4nqmtc9cr3u" \
                     -X GET https://integration.shopatron.com/api/v2/shipment?shipmentStatus=BACKORDER\&orderID=$1\&manufacturerID=10637`

   #*****   If the order status string is null then return *****
   if [[ "$orderStatus" == "" ]]; then
       echo "$1 orderID has no Backorder shipments"
       return
   fi

   totalCount=`echo "$orderStatus" | \
                    python -c 'import sys, json; print json.load(sys.stdin)["totalCount"]'`

   #*****   If the total count is zero then return *****
   if [ $totalCount -eq 0 ]; then
       echo "$1 orderID has no Backorder shipments\n"
       return
   fi

   export ii=0
   export jj=0
   kk=0
   orderItemIDList=""
   quantityList=""
   for ((index=0;index<totalCount;index++));
   do
      numOfOrderItems=`echo "$orderStatus" | python -c 'import sys, os, json; items_dict = json.load(sys.stdin)["collection"][int(os.environ["ii"])]["items"]; print len(items_dict)'`
      jj=0;
      for ((lindex=0;lindex<numOfOrderItems;lindex++));
      do
         let kk++
         orderItemID=`echo "$orderStatus" | python -c 'import sys, os, json; print json.load(sys.stdin)["collection"][int(os.environ["ii"])]["items"][int(os.environ["jj"])]["orderItemID"]'`
         quantity=`echo "$orderStatus" | python -c 'import sys, os, json; print json.load(sys.stdin)["collection"][int(os.environ["ii"])]["items"][int(os.environ["jj"])]["quantity"]'`
         orderItemIDList="$orderItemIDList $orderItemID"
         quantityList="$quantityList $quantity"
         let jj++
      done
      let ii++
   done

cat << EOF > order.py
#!/usr/bin/python
import sys, json;
data = {}
data["orderID"] = $orderID
data["sendEmails"] = True
data["rectifyOrder"] = True
itemAssign = []

for index in range(0, int(sys.argv[1])):
   dict = {}
   dict["orderItemID"] = int(sys.argv[2+index])
   dict["quantity"] = int(sys.argv[2+int(sys.argv[1])+index])
   itemAssign.append(dict)

packageAssignment = [{}]
packageAssignment[0]["autoAssign"] = True
packageAssignment[0]["shipmentStatus"] = "READY"
packageAssignment[0]["itemAssign"] = itemAssign
data["packageAssignment"] = packageAssignment

with open('data.json', 'w') as outfile:
    json.dump(data, outfile)

EOF
chmod 755 order.py
json_data=`./order.py $kk $orderItemIDList $quantityList`

   #*****   If there is a back order the get the shipment id *****
   orderResults=`curl -H "Content-Type: application/json" \
                           -H "Authorization: Bearer $access_token" \
                           -H "API-Key: t7zwmqzt8pbns4nqmtc9cr3u" \
                           --data @data.json \
                           -X POST https://integration.shopatron.com/api/v2/action/order/assign`

   export jj=0
   shipmentCount=`echo "$orderResults" | python -c 'import sys, os, json; print len(json.load(sys.stdin)["shipments"])'`
   for ((lindex=0;lindex<shipmentCount;lindex++));
   do
      orderID=`echo "$orderResults" | python -c 'import sys, os, json; print json.load(sys.stdin)["orderID"]'`
      orderStatus=`echo "$orderResults" | python -c 'import sys, os, json; print json.load(sys.stdin)["orderStatus"]'`

      shipmentID=`echo "$orderResults" | python -c 'import sys, os, json; print json.load(sys.stdin)["shipments"][int(os.environ["jj"])]["shipmentID"]'`
      shipmentStatus=`echo "$orderResults" | python -c 'import sys, os, json; print json.load(sys.stdin)["shipments"][int(os.environ["jj"])]["shipmentStatus"]'`
      #echo "OrderID = $orderID  ShipmentID = $shipmentID  Shipment Status = $shipmentStatus OrderStatus = $orderStatus"
      printf "OrderID: %-10s  ShipmentID: %-10s  OrderStatus: %-10s  OrderStatus: %-s\n\n" $orderID $shipmentID $shipmentStatus $orderStatus
      let jj++
   done

}

######################################################################
# Parameter: fileName                                                #
# Read the data file (contains orderID in each line) passed as a     #
# parameter to this program andnvooke the function                   #
# process_single_orderID with orderID                                #
######################################################################
if [ $# -eq 0 ]; then
    echo "Usage ./order <fileName>"
    exit
fi

while read orderID; do
  if [[ "$orderID" = "" ]]; then
      echo "orderID is NULL"
  else
     process_single_orderID "$orderID" 
  fi
done <$1
