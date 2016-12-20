#!/usr/bin/python
import sys, json;
data = {}
data["orderID"] = 16957766
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

