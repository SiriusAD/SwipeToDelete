/*
 * Copyright (c) 2011-2014 BlackBerry Limited.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import bb.cascades 1.4
import bb.device 1.3 //used for DisplayInfo

Page {

    id: root

    property int deviceWidth: displayInfo.pixelSize.width //Used below to set a threshold value for elastic return

    attachedObjects: [
        DisplayInfo {
            id: displayInfo
        },
        GroupDataModel {
            id: groupDataModel
        }
    ]

    ListView {

        id: listView
        dataModel: groupDataModel

        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill

        property int listDeviceWidth: deviceWidth //Items in listview have a different scope to the page scope. They can access properties from their parent listView.

        function deleteItem(indexPath) {
            groupDataModel.removeAt(indexPath)
        }

        listItemComponents: [
            ListItemComponent {
                type: "item"
                Container {
                    id: itemRoot
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill

                    layout: DockLayout {
                    }

                    //TODO add a container here (goes below swipeRoot), to implement listitem actions

                    Container {

                        id: swipeRoot
                        layout: DockLayout {
                        }

                        Container {
                            background: ui.palette.background
                            
                            horizontalAlignment: HorizontalAlignment.Fill
                            verticalAlignment: VerticalAlignment.Fill

                            StandardListItem {
                                title: "Definitely Maybe"
                                description: "Oasis"
                                imageSource: "asset:///images/oasis.jpg"
                                status: "1994"
                            }
                        }

                        onTranslationXChanged: {
                            swipeRoot.opacity = 1 - swipeRoot.translationX / itemRoot.dragThreshold        //The change in opacity makes the removal visible.
                        }
                    }

                    attachedObjects: [
                        ImplicitAnimationController {
                            id: translationControllerX
                            propertyName: "translationX"
                        }
                    ]

                    ListItem.onActivationChanged: {
                        //This signal is emitted by a ListItem when it is no longer active (losses focus) in the listView
                        if (active == false) {
                            releaseItem();        
                        }
                    }

                    property real dx: 0
                    property real currentX: 0    
                    property real dragThreshold: itemRoot.ListItem.view.listDeviceWidth * 0.8    //The threshold is set to 80% of device width. 
                    property bool thisItem: false        //Helpful state variable. Will be used in move events to check if the event started at this item.

                    function releaseItem() {
                        //It the item has translated, move it back to it's original position.
                        if (swipeRoot.translationX != 0) {
                            resetItem.play();
                        }
                    }

                    function removeItem() {
                        itemRoot.ListItem.view.deleteItem(itemRoot.ListItem.indexPath);
                    }

                    animations: [
                        SequentialAnimation {
                            id: resetItem
                            target: swipeRoot
                            //for a snappy elastic animation 
                            animations: [
                                TranslateTransition {
                                    toX: 11
                                    duration: 300 * 0.7
                                },
                                TranslateTransition {
                                    toX: 13
                                    duration: 300 * 0.3
                                },
                                TranslateTransition {
                                    toX: 0
                                    duration: 300 * 0.1
                                }
                            ]
                        }
                    ]

                    onTouchExit: {
                        releaseItem();
                        thisItem = false
                    }

                    onTouch: {

                        // Disabling implicit animation this will make movements snappy.
                        
                        translationControllerX.enabled = false;

                        //check event type and execute what is needed.
                        if (event.isCancel()) {
                            releaseItem();
                        } else if (event.isDown()) {

                            resetItem.stop();
                            releaseItem();

                            dx = event.windowX;       
                            thisItem = true            //Touch events started at this item

                        } else if (event.isMove()) {
                            currentX = event.windowX - dx;

                            if (thisItem == false) {        //Touch event did not start at this item.
                                releaseItem();
                                return;
                            }

                            //If the dragThreshold was exceeded, remove the item. Else, translate to currentX

                            if (currentX > dragThreshold) {
                                swipeRoot.translationX = dragThreshold;
                                removeItem()
                            } else {
                                swipeRoot.translationX = currentX
                            }
                            
                        } else if (event.isUp()) {
                            releaseItem();
                        }

                        // Re-enable implicit animation.
                        translationControllerX.enabled = true;
                    }

                }
            }
        ]

    }

    onCreationCompleted: {
        
        //Add some items to test swipe
        var item = {}
        groupDataModel.insert(item)
        groupDataModel.insert(item)
        groupDataModel.insert(item)
        groupDataModel.insert(item)
        groupDataModel.insert(item)
        groupDataModel.insert(item)
    }

}
