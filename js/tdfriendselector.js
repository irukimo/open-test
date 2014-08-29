/*jslint devel: true, bitwise: false, undef: false, browser: true, continue: false, debug: false, eqeq: false, es5: false, type: false, evil: false, vars: false, forin: false, white: true, newcap: false, nomen: true, plusplus: false, regexp: true, sloppy: true */
/*globals jQuery, FB */

/*!
 * These Days Friend Selector
 * @authors: Bram Verdyck, Keegan Street
 */
var TDFriendSelector = (function(module, $) {

	// Public functions
	var init, setFriends, getFriends, getFriendById, newInstance,

	// Private variables
	settings, friends, en_friends, ch_friends, me,
	$friends, $container, $friendsContainer, $searchField, $selectedCount, $selectedCountMax, $pageNumber, $pageNumberTotal, $pagePrev, $pageNext, $buttonClose, $buttonOK,

	// Private functions
	$getFriendById, buildFriendSelector, sortFriends, log;

	/////////////////////////////////////////
	// PUBLIC FUNCTIONS FOR GLOBAL PLUGIN
	// They are public because they are added to module and returned
	/////////////////////////////////////////

	/**
	 * Initialise the plugin and define global options
	 */
	init = function(options) {

		// Default settings
		settings = {
			speed                    : 500,
			debug                    : false,
			textSelect               : 'select',
			disabledClass            : 'TDFriendSelector_disabled',
			friendSelectedClass      : 'TDFriendSelector_friendSelected',
			friendDisabledClass      : 'TDFriendSelector_friendDisabled',
			friendFilteredClass      : 'TDFriendSelector_friendFiltered',
			containerSelector        : '#TDFriendSelector',
			friendsContainerSelector : '.TDFriendSelector_friendsContainer',
			searchFieldSelector      : '#TDFriendSelector_searchField',
			selectedCountSelector    : '.TDFriendSelector_selectedCount',
			selectedCountMaxSelector : '.TDFriendSelector_selectedCountMax',
			pageNumberSelector       : '#TDFriendSelector_pageNumber',
			pageNumberTotalSelector  : '#TDFriendSelector_pageNumberTotal',
			pagePrevSelector         : '#TDFriendSelector_pagePrev',
			pageNextSelector         : '#TDFriendSelector_pageNext',
			buttonCloseSelector      : '#TDFriendSelector_buttonClose',
			buttonOKSelector         : '#TDFriendSelector_buttonOK'
		};

		// Override defaults with arguments
		$.extend(settings, options);

		// Select DOM elements
		$container        = $(settings.containerSelector);
		$friendsContainer = $container.find(settings.friendsContainerSelector);
		$searchField      = $container.find(settings.searchFieldSelector);
		$selectedCount    = $container.find(settings.selectedCountSelector);
		$selectedCountMax = $container.find(settings.selectedCountMaxSelector);
		$pageNumber       = $container.find(settings.pageNumberSelector);
		$pageNumberTotal  = $container.find(settings.pageNumberTotalSelector);
		$pagePrev         = $container.find(settings.pagePrevSelector);
		$pageNext         = $container.find(settings.pageNextSelector);
		$buttonClose      = $container.find(settings.buttonCloseSelector);
		$buttonOK         = $container.find(settings.buttonOKSelector);
	};

	/**
	 * If your website has already loaded the user's Facebook friends, pass them in here to avoid another API call.
	 */
	/**
	 * Here we sort friends according to the self-defined closeness
	 */
	setFriends = function(input, callback) {
		var i, len;
		if (!input || input.length === 0) {
			return;
		}
		input = Array.prototype.slice.call(input);
		for (i = 0, len = input.length; i < len; i += 1) {
			input[i].upperCaseName = input[i].name.toUpperCase();
		}

		sortFriends(input, callback);
		
	};

	getFriends = function() {
		return friends;
	};

	/**
	 * Use this function if you have a friend ID and need to know their name
	 */
	getFriendById = function(id) {
		var i, len;
		id = id.toString();
		for (i = 0, len = friends.length; i < len; i += 1) {
			if (friends[i].id === id) {
				return friends[i];
			}
		}
		return null;
	};

	/**
	 * Create a new instance of the friend selector
	 * @param options An object containing settings that are relevant to this particular instance
	 */
	newInstance = function(options) {
		// Public functions
		var showFriendSelector, hideFriendSelector, getselectedFriendIds, setDisabledFriendIds, filterFriends, reset,

		// Private variables
		instanceSettings, selectedFriendIds = [], selectedFriendNames = [], disabledFriendIds = [], numFilteredFriends = 0,

		// Private functions
		bindEvents, unbindEvents, updateFriendsContainer, updatePaginationButtons, selectFriend;

		if (!settings) {
			log('Cannot create a new instance of TDFriendSelector because the plugin not initialised.');
			return false;
		}

		// Default settings
		instanceSettings = {
			maxSelection             : 4,
			minSelection             : 1,
			friendsPerPage           : 10,
			autoDeselection          : false, // Allow the user to keep on selecting once they reach maxSelection, and just deselect the first selected friend
			filterCharacters         : 1, // Set to 3 if you would like the filter to only run after the user has typed 3 or more chars
			callbackFriendSelected   : null,
			callbackFriendUnselected : null,
			callbackMaxSelection     : null,
			callbackSubmit           : null
		};

		// Override defaults with arguments
		$.extend(instanceSettings, options);

		/////////////////////////////////////////
		// PUBLIC FUNCTIONS FOR AN INSTANCE
		/////////////////////////////////////////

		/**
		 * Call this function to show the interface
		 */
		showFriendSelector = function(callback) {
			var i, len;
			log('TDFriendSelector - newInstance - showFriendSelector');
			if (!$friends) {
				return buildFriendSelector(function() {
					showFriendSelector(callback);
				});
			} else {
				bindEvents();
				// Update classnames to represent the selections for this instance
				$friends.removeClass(settings.friendSelectedClass + ' ' + settings.friendDisabledClass + ' ' + settings.friendFilteredClass);
				for (i = 0, len = friends.length; i < len; i += 1) {
					if ($.inArray(friends[i].id, selectedFriendIds) !== -1) {
						$($friends[i]).addClass(settings.friendSelectedClass);
					}
					if ($.inArray(friends[i].id, disabledFriendIds) !== -1) {
						$($friends[i]).addClass(settings.friendDisabledClass);
					}
				}
				// Reset filtering
				numFilteredFriends = 0;
				$searchField.val("");
				// Update paging
				$selectedCount.html(selectedFriendIds.length);
				$selectedCountMax.html(instanceSettings.maxSelection);
				updateFriendsContainer(1);
				updatePaginationButtons(1);
				$container.fadeIn(500);
				if (typeof callback === 'function') {
					callback();
				}
			}
		};

		hideFriendSelector = function() {
			unbindEvents();
			$container.fadeOut(500);
		};

		getselectedFriendIds = function() {
			return selectedFriendIds;
		};

		getselectedFriendNames = function() {
			return selectedFriendNames;
		};
		/**
		 * Disabled friends are greyed out in the interface and are not selectable.
		 */
		setDisabledFriendIds = function(input) {
			disabledFriendIds = input;
		};

		/**
		 * Hides friends whose names do not match the filter
		 */
		filterFriends = function(filter) {
			var i, len;
			numFilteredFriends = 0;
			$friends.removeClass(settings.friendFilteredClass);
			if (filter.length >= instanceSettings.filterCharacters) {
				filter = filter.toUpperCase();
				for (i = 0, len = friends.length; i < len; i += 1) {
					if (friends[i].upperCaseName.indexOf(filter) === -1) {
						$($friends[i]).addClass(settings.friendFilteredClass);
						numFilteredFriends += 1;
					}
				}
			}
			updateFriendsContainer(1);
			updatePaginationButtons(1);
		};

		/**
		 * Remove selections, clear disabled list, go to page 1, etc
		 */
		reset = function() {
			if (!friends || friends.length === 0) {
				return;
			}
			$friendsContainer.empty();
			selectedFriendIds = [];
			selectedFriendNames = [];
			$selectedCount.html("");
			disabledFriendIds = [];
			numFilteredFriends = 0;
			$searchField.val("");
			updatePaginationButtons(1);
		};

		/////////////////////////////////////////
		// PRIVATE FUNCTIONS FOR AN INSTANCE
		/////////////////////////////////////////

		// Add event listeners
		bindEvents = function() {
			$buttonClose.bind('click', function(e) {
				e.preventDefault();
				hideFriendSelector();
			});

			$buttonOK.bind('click', function(e) {
				e.preventDefault();
				if (selectedFriendIds.length < instanceSettings.minSelection) {
					alert("請選至少" + instanceSettings.minSelection + "位朋友！");
				} else {
					hideFriendSelector();
					if (typeof instanceSettings.callbackSubmit === "function") { 
						friends.forEach(function(elem){
							delete elem["upperCaseName"];
							id = elem.id;
							name = elem.ch_name;
							delete elem["name"];
							delete elem["ch_name"];
							delete elem["id"];
							delete elem["closeness"];
							elem[id] = name;
							});
						instanceSettings.callbackSubmit(me, selectedFriendNames, friends); 
					}
				}
			});

			$searchField.bind('keyup', function(e) {
				filterFriends($(this).val());
			});

			// The enter key shouldnt do anything in the search field
			$searchField.bind('keydown', function(e) {
				if (e.which === 13) {
					e.preventDefault();
					e.stopPropagation();
				}
			});

			$pagePrev.bind('click', function(e) {
				var pageNumber = parseInt($pageNumber.text(), 10) - 1;
				e.preventDefault();
				if (pageNumber < 1) { return; }
				updateFriendsContainer(pageNumber);
				updatePaginationButtons(pageNumber);
			});

			$pageNext.bind('click', function(e) {
				var pageNumber = parseInt($pageNumber.text(), 10) + 1;
				e.preventDefault();
				if ($(this).hasClass(settings.disabledClass)) { return; }
				updateFriendsContainer(pageNumber);
				updatePaginationButtons(pageNumber);
			});

			$(window).bind('keydown', function(e) {
				if (e.which === 13) {
					// The enter key has the same effect as the OK button
					e.preventDefault();
					if (selectedFriendIds.length < instanceSettings.minSelection) {
						alert("請選至少" + instanceSettings.minSelection + "位朋友！");
					} else {
						e.stopPropagation();
						hideFriendSelector();
						if (typeof instanceSettings.callbackSubmit === "function") { 
							friends.forEach(function(elem){
								delete elem["upperCaseName"];
								id = elem.id;
								name = elem.ch_name;
								delete elem["name"];
								delete elem["ch_name"];
								delete elem["id"];
								delete elem["closeness"];
								elem[id] = name;
							});
							instanceSettings.callbackSubmit(me, selectedFriendNames, friends); }
					}
				} else if (e.which === 27) {
					// The escape key has the same effect as the close button
					e.preventDefault();
					e.stopPropagation();
					hideFriendSelector();
				}
			});
		};

		// Remove event listeners
		unbindEvents = function() {
			$buttonClose.unbind('click');
			$buttonOK.unbind('click');
			$friendsContainer.children().unbind('click');
			$searchField.unbind('keyup');
			$searchField.unbind('keydown');
			$pagePrev.unbind('click');
			$pageNext.unbind('click');
			$(window).unbind('keydown');
		};

		// Set the contents of the friends container
		updateFriendsContainer = function(pageNumber) {
			var firstIndex, lastIndex;
			firstIndex = (pageNumber - 1) * instanceSettings.friendsPerPage;
			lastIndex = pageNumber * instanceSettings.friendsPerPage;
			$friendsContainer.html($friends.not("." + settings.friendFilteredClass).slice(firstIndex, lastIndex));
			$friendsContainer.children().bind('click', function(e) {
				e.preventDefault();
				selectFriend($(this));
			});
		};

		updatePaginationButtons = function(pageNumber) {
			var numPages = Math.ceil((friends.length - numFilteredFriends) / instanceSettings.friendsPerPage);
			$pageNumber.html(pageNumber);
			$pageNumberTotal.html(numPages);
			if (pageNumber === 1 || numPages === 1) {
				$pagePrev.addClass(settings.disabledClass);
			} else {
				$pagePrev.removeClass(settings.disabledClass);
			}
			if (pageNumber === numPages || numPages === 1) {
				$pageNext.addClass(settings.disabledClass);
			} else {
				$pageNext.removeClass(settings.disabledClass);
			}
		};

		selectFriend = function($friend) {
			var friendId, i, len, removedId;
			friendId = $friend.attr('data-id');
			friendName = $friend.attr('data-name');

			// If the friend is disabled, ignore this
			if ($friend.hasClass(settings.friendDisabledClass)) {
				return;
			}

			if (!$friend.hasClass(settings.friendSelectedClass)) {
				// If autoDeselection is enabled and they have already selected the max number of friends, deselect the first friend
				if (instanceSettings.autoDeselection && selectedFriendIds.length === instanceSettings.maxSelection) {
					removedId = selectedFriendIds.splice(0, 1);
					selectedFriendNames.splice(0, 1);
					$getFriendById(removedId).removeClass(settings.friendSelectedClass);
					$selectedCount.html(selectedFriendIds.length);
				}
				if (selectedFriendIds.length < instanceSettings.maxSelection) {
					// Add friend to selectedFriendIds
					if ($.inArray(friendId, selectedFriendIds) === -1) {
						selectedFriendIds.push(friendId);
						selectedFriendNames.push(friendName);
						$friend.addClass(settings.friendSelectedClass);
						$selectedCount.html(selectedFriendIds.length);
						log('TDFriendSelector - newInstance - selectFriend - selected IDs: ', selectedFriendIds);
						if (typeof instanceSettings.callbackFriendSelected === "function") { instanceSettings.callbackFriendSelected(friendId); }
					} else {
						log('TDFriendSelector - newInstance - selectFriend - ID already stored');
					}
				}

			} else {
				// Remove friend from selectedFriendIds
				for (i = 0, len = selectedFriendIds.length; i < len; i += 1) {
					if (selectedFriendIds[i] === friendId) {
						selectedFriendIds.splice(i, 1);
						selectedFriendNames.splice(i, 1);
						$friend.removeClass(settings.friendSelectedClass);
						$selectedCount.html(selectedFriendIds.length);
						if (typeof instanceSettings.callbackFriendUnselected === "function") { instanceSettings.callbackFriendUnselected(friendId); }
						return false;
					}
				}
			}

			if (selectedFriendIds.length === instanceSettings.maxSelection) {
				if (typeof instanceSettings.callbackMaxSelection === "function") { instanceSettings.callbackMaxSelection(); }
			}
		};

		// Return an object with access to the public members
		return {
			showFriendSelector   : showFriendSelector,
			hideFriendSelector   : hideFriendSelector,
			getselectedFriendIds : getselectedFriendIds,
			setDisabledFriendIds : setDisabledFriendIds,
			filterFriends        : filterFriends,
			reset                : reset
		};
	};

	/////////////////////////////////////////
	// PRIVATE FUNCTIONS FOR GLOBAL PLUGIN
	/////////////////////////////////////////

	$getFriendById = function(id) {
		var i, len;
		id = id.toString();
		for (i = 0, len = friends.length; i < len; i += 1) {
			if (friends[i].id === id) {
				return $($friends[i]);
			}
		}
		return $("");
	};

	/**
	 * Load the Facebook friends and build the markup
	 */
	buildFriendSelector = function(callback) {
		var buildMarkup, buildFriendMarkup;
		log("buildFriendSelector");

		if (!FB) {
			log('The Facebook SDK must be initialised before showing the friend selector');
			return false;
		}

		// Check that the user is logged in to Facebook
		FB.getLoginStatus(function(response) {
			var loadNameBarrier = new CallbackBarrier();
			if (response.status === 'connected') {
				// Load Facebook friends
				
				loadNameBarrier.setBarrier();
				FB.api('/me/friends?locale=zh_TW&fields=id,name', function(response) {
					if (response.data) {
						ch_friends = response.data;
						loadNameBarrier.tryCallback();
					} else {
						log('TDFriendSelector - buildFriendSelector - No friends returned');
						return false;
					}
				});
				
				loadNameBarrier.setBarrier();
				FB.api('/me/friends?locale=en_US&fields=id,name', function(response) {
					if (response.data) {
						en_friends = response.data;
						loadNameBarrier.tryCallback();
					} else {
						log('TDFriendSelector - buildFriendSelector - No friends returned');
						return false;
					}
				});
			}

			loadNameBarrier.finalize(function(){
				friends = ch_friends;

				function findSameID(array, id){
					for (var i = 0; i < array.length; i++){
						if (array[i]["id"] == id){
							return array[i]["name"];
							break;
						}
					}
				};

				friends.forEach(function(elem, index, array){
					en_name = findSameID(en_friends, elem["id"]);
					if (en_name != elem["name"]) {
						elem["ch_name"] = elem["name"];
						elem["name"] += " (" + en_name + ")";
						
						console.log(elem["name"]);
					}
				});

				for (i = 0, len = friends.length; i < len; i += 1) {
					friends[i].upperCaseName = friends[i].name.toUpperCase();
				}

				// Build the markup
				buildMarkup();
				// Call the callback
				if (typeof callback === 'function') { callback(); }
			});
		});

		// Build the markup of the friend selector
		buildMarkup = function() {
			var i, len, html = '';
			for (i = 0, len = friends.length; i < len; i += 1) {
				html += buildFriendMarkup(friends[i]);
			}
			
			$friends = $(html);
		};

		// Return the markup for a single friend
		buildFriendMarkup = function(friend) {
			return '<a href="#" class="TDFriendSelector_friend TDFriendSelector_clearfix touch_on" data-id="' + friend.id + '" data-name="' + friend.ch_name + '">' +
					'<img src="//graph.facebook.com/' + friend.id + '/picture?type=square" width="50" height="50" alt="' + friend.name + '" class="TDFriendSelector_friendAvatar" />' +
					'<div class="TDFriendSelector_friendName">' + 
						'<span>' + friend.name + '</span>' +
						'<span class="TDFriendSelector_friendSelect">' + settings.textSelect + '</span>' +
					'</div>' +
				'</a>';
		};
	};

	/**
	 * sortFriends: 	
	 * @param  {id, name} input    [description]
	 * @return {id, name} friends  in the order of number of mutual friends
	 */
	// sortFriends = function(input, callback) {
	// 	FB.api('/me?locale=zh_TW', function (resp) {
	// 		myID = resp.id;
	// 		me = resp.name;
 //      console.log('my ID: ' + myID);
 //      var barrier = new CallbackBarrier();
 //       console.log(input);
	// 		for (var i in input) {
	// 			if (i > 0) {
	// 				input[i].closeness = 0;
	// 				continue;
	// 			}
	// 			(function(i) {
	// 				friendID = input[i].id;
	// 				barrier.setBarrier();

	// 				FB.api(
	// 	        "/" + myID + "/mutualfriends/" + friendID,
	// 	        function (response) {
	// 	          if (response && !response.error) {
	// 	            /* handle the result */
	// 	            input[i].closeness = response.data.length;
	// 	            // console.log("name: " + input[i].name + " closeness: " + input[i].closeness);
	// 	            barrier.tryCallback();
	// 	          }
	// 	      });
	// 			})(i);
	// 		}

	// 		barrier.finalize(function(){
	// 		  console.log("all the callbacks executed.");
	// 		  input = input.sort(sortByCloseness);
	// 		  friends = input;
	// 		  callback();
	// 		});
	// 	}); 
	// };

	sortByCloseness = function(friend1, friend2) {
		if (friend1.closeness === friend2.closeness) { return 0; }
		if (friend1.closeness > friend2.closeness) { return -1; }
		if (friend1.closeness < friend2.closeness) { return 1; }
		// if (typeof friend1.closeness == "undefined" && 
		// 	  typeof friend2.closeness != "undefined") { return 1; }
	};

	log = function() {
		if (settings && settings.debug && window.console) {
			console.log(Array.prototype.slice.call(arguments));
		}
	};

	module = {
		init          : init,
		setFriends    : setFriends,
		getFriends    : getFriends,
		getFriendById : getFriendById,
		newInstance   : newInstance
	};
	return module;

}(TDFriendSelector || {}, jQuery));

