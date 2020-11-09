openstack domain create tdomain
openstack project create --domain tdomain tproject
openstack project create --domain tdomain atproject
openstack user create --domain tdomain --password password tuser
openstack user create --domain tdomain --password password tnuser
openstack role add --user tuser --project tproject  _member_
openstack role add --user tnuser --project tproject  _member_
openstack role add --user tnuser --project atproject  _member_
openstack role add --user tuser --project atproject  _member_
openstack role add --user tuser --project tproject  admin
openstack role add --user tuser --project atproject  admin
