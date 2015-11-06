# Virtual-Tourist

======================
Virtual-Tourist README
======================


“Virtual Tourist” is an app that allows the user to pin a location anywhere in the world and show pictures related to that location. The app uses the Flickr Picture Search API via map coordinates to find public picture.  The app saves the tourist location along with the latest set of pictures.


----------------------
Tourist Drop Pin Scene
----------------------

Files:
------
DropPinViewController.swift

The drop pin scene allows the user to move and zoom to any map location, where a long tap will place a pin. If you hold your finger down without releasing it from the screen, you can drag the pin on map before “dropping” it.

How to use the drop pin scene:

•	Find a location by dragging the map and zooming in.
•	Long tap the screen at the point where you want to add a pin.  A pin will drop after 1 second.
•	Tap the new pin to transition to the pin/picture view.


-------------------------
Tourist Pin/Picture Scene
-------------------------

Files:
------
PinPictureViewController.swift
PicCollectionCell.swift
VTClient.swift
VTConstants.swift
ImageCache.swift

The pin/picture scene automatically calls the Flickr picture search API and pulls 21 pictures based on the map coordinates of the selected pin (latitude & longitude) and places them in a collection view. After the picture are captured, they will be recalled if necessary using a caching technique.

How to use the pin/picture scene:

•	Tap the “New Collection” button to refresh the pictures (calls the Flickr API).
•	Tap any picture to select for deletion. The picture will look greyed out in appearance.  You can select multiple pictures.
•	Tap the greyed out picture again to de-select it.
•	The bottom button will dynamically change. Tap the “Remove Selected Pictures” button when ready to delete the selected pictures.
•	Tap the OK button to exit the screen and go back to the drop in view.


----------------
Other App Files:
----------------

Delegate Files:
---------------

AppDelegate.swift: Default delegate file


Object Files:
-------------

Pins.swift
•	Primary object for storing Pins data
•	One-to-Many relationship with Pictures object

Pictures.swift
•	Object for storing picture data
•	One-to-one relationship with Pins object


Images:
-------
placeholder1.jpg
