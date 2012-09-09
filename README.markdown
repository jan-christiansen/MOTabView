MOTabView
=========

View to present several tabs similar to the view used in Safari for
iOS. The following screenshots show an example application that is
part of the library.

![](https://github.com/plancalculus/MOTabView/raw/master/Screenshots/MOTabViewExample1.png)
![](https://github.com/plancalculus/MOTabView/raw/master/Screenshots/MOTabViewExample2.png)


Features
--------

###Titles###

By implementing the methods

    - (NSString *)titleForIndex:(NSInteger)index;

and

    - (NSString *)subtitleForIndex:(NSInteger)index;

in the data source delegate of a `MOTabView`, the title and subtitle,
that are displayed above a tab can be set.

###Adding a New Tab###

The property `addingStyle` of a tab view can be used to set how a new
tab is added. If the property is set to `MOTabViewAddingAtLastIndex` a
new tab is added at the right end of the tabs, which resembles the
behavior of safari prior to iOS6. If the property is set
`MOTabViewAddingAtNextIndex` a new tab is added to the right of the
current tab. This behaviour resembles safari in iOS6.

###NavigationBar###

The class `MOTabView` provides a property `navigationBarHidden` that
determines whether the view shows a navigation bar when a view is
selected. The bar displays the text that is provided by
`titleForIndex:`. Similar to the safari ios view the navigation bar
disappears when another tab is selected.


Usage
-----

Import the static library as a sub-project into your main project.


Requirements
------------

You need iOS 4 or later as the library uses automatic reference
counting lite. Furthermore, as the library uses the new enum
declaration style you need XCode 4.5, which is currently only
available as developer preview.


License
-------

`MOTabView` is released under Modified BSD License.
