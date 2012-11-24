# Shelby 2.0 - iPad App 

## App Sections

### 1. Video Player

#### Video Player Functionality
- Swipeable Video Players
- Swipeable Playlist
	- Playlist can refresh dynamically
	- Playlist can grow in size 
- Custom Playback Controls
	- Controls should be static, but control video on screen (even when new video loads)
- Sharing Actions
	- Easy: Email, Twitter, Facebook 
	- Medium: Queue
	- Complicated: Rolling

#### Video Player Object
- AVPlayer
	- Benefit of access to AVPlayerLayer
	- Built-in but undocumented AirPlay support

#### Video Playback Controls
- Playback Toggle (Play/Pause)
- AirPlay Toggle   
- Scrubber with timer
- Close Video Player (Cancel/Done/Back)

#### Video Non-Playback Controls
- Toggle UI
	- Toggle Playback Controls
	- Toggle PlayerCard (Current Video)
	- Toggle Playlist (Next Videos)	
- Action Button
	- Native Twitter Sharing
	- Native Facebook Sharing
	- Native Email Sharing
	- Queuing
		- Save FrameID
		- Save Queue Timestamp
	- Rolling
		- Custom feature to mimic Facebook

### 2. Categories
- 3x2 or 3x3 Thumbnails with data and text
- Easy to implement with UICollectionViews
- Can be implemented manually

### 3. Me

#### Logged-Out Experience
- Add Login Flow (Should be pop-over screen with three text fields)

#### Logged-In Experience
- Sync Queue with Shelby Account
	- Possible complication: Offline user who queues, but then syncs with existing account after queuing when offline.
- Add Roll Button
- Rol Playlist should read into Video Player


## API Routes
- Public Roll
- Watch Later Roll
- Email TokenController (modify to accept username if possible)
- Explore Rolls (routes will need modifications)

## Thoughts
App should support **iOS 6** only. 

- Pros:
	- UIActivity & UIActivityViewController (Apple's new Sharing Screen)
		- Native Facebook Sharing
	- UICollectionView for Categories
	- Easier to integrate AirPlay
- Cons:
	- No support for iPad 1
	- Access to only 70% of iOS market (projection if we release in January)

There are a few tought aspects of the app.

- Duplicating Online-Offline experience for Queue
	- How much information do I need to store?
	- What if the structure or API route parameters change?	 