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

The title that is presented on top of a tab as well as the title that
is shown on the optional navigation bar are text fields. If you set
the `editableTitles` property of a tab view to `YES` you can edit that
titles. By default this property is set to `NO`. The subtitle that is
shown on top of a tab is currently not editable.

By implementing the methods

    - (NSString *)titleForIndex:(NSInteger)index;

and

    - (NSString *)subtitleForIndex:(NSInteger)index;

in the data source delegate of a `MOTabView`, the title and subtitle,
that are displayed above a tab can be set. More precisely, when a
title is about to be displayed, the tab view asks its delegate for a
title.


###Adding a New Tab###

The property `addingStyle` of a tab view can be used to set how a new
tab is added. If the property is set to `MOTabViewAddingAtLastIndex` a
new tab is added at the right end of the tabs, which resembles the
behavior of safari prior to iOS6. If the property is set to
`MOTabViewAddingAtNextIndex`, a new tab is added to the right of the
current tab. This behaviour resembles safari in iOS6.


###Navigation Bar###

The class `MOTabView` provides a property `navigationBarHidden` that
determines whether the view shows a navigation bar when a view is
selected. The bar displays the text that is provided by
`titleForIndex:`. Similar to the safari ios view the navigation bar
disappears when another tab is selected. When the content view of a
tab is a subclass of `UITableView` the navigation bar is added as a
header view to the table view. That is, if the table view is scrolled,
the navigation bar scrolls as well. The treatment of the navigation
bar is very similar to the treatment of the navigation bar of the
safari web view.


###Delegates###

####`dataSource` Delegate####

A `MOTabView` has two delegates, one is called `dataSource` and the
other is called `delegate`. The data source delegate is asked for
data, like the title of a tab of the view that is displayed as content
of the tab while the delegate is informed on several occasions, for
example, when a tab is about to be deleted or has been deleted.


####`delegate` Delegate####




Usage
-----

Import the static library as a sub-project into your main project. As
static libraries do not provide a mechanism for providing additional
files you have to copy the images that are used to display the delete
button of a tab to your project. Simply drag and drop the files
`"closeButton.png"` and `"closeButton@2x.png"` from the folder
`MOTabView/Images` of the `MOTabView` project into your super-project.


Requirements
------------

You need iOS 4 or later as the library uses automatic reference
counting lite. Furthermore, as the library uses the new enum
declaration style you need XCode 4.5.


License
-------

`MOTabView` is released under Modified BSD License.
