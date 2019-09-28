const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp()
// // Create and Dep;loy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("follower created", snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // create followed users posts ref
        const followedUserPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('userPosts');

        // create following user's timeline ref
        const timelinePostsRef = admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts');

        // get followed users posts
        const querySnapshot = await followedUserPostsRef.get();

        // add each user post to following user's timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        });
    });

exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot,context) => {
        console.log("follower deleted", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
});

// when post is created add post to timeline of each follower of each post owner
exports.onCreatePost = functions.firestore
	.document('/posts/{userId}/userPosts/{postId}')
	.onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // get all followers of user who made post
		const userFollowersRef = admin
			.firestore()
			.collection('followers')
			.doc(userId)
			.collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    //add new post to each follower's timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;
				admin
					.firestore()
					.collection('timeline')
					.doc(followerId)
					.collection('timelinePosts')
					.doc(postId)
					.set(postCreated);
    });
});

exports.onUpdatePost = functions.firestore.document('/posts/{userId}/userPosts/{postId}').onUpdate(async (change, context) => {
    const postUpdated = change.after.data()
    const userId = context.params.userId;
    const postId = context.params.postId;
		const userFollowersRef = admin
			.firestore()
			.collection('followers')
			.doc(userId)
			.collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    // update each post in each follower's timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;
				admin
					.firestore()
					.collection('timeline')
					.doc(followerId).collection('timelinePosts')
					.doc(postId)
					.get()
					.then(doc => {
							if(doc.exists) {
									doc.ref.update(postUpdated);
							}
					});
		});
});

exports.onDeletePost = functions.firestore
	.document('/posts/{userId}/userPosts/{postId}')
	.onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;
		
		const userFollowersRef = admin
			.firestore()
			.collection('followers')
			.doc(userId)
			.collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    // delete each post in each follower's timeline
    querySnapshot.forEach(doc => {
        const followerId = doc.id;
				admin
					.firestore()
					.collection('timeline')
					.doc(followerId)
					.collection('timelinePosts')
					.doc(postId)
					.get()
					.then(doc => {
            if(doc.exists) {
                doc.ref.delete();
            }
        });
    });
})

exports.onCreateActivityFeedItem = functions.firestore
	.document('/feed/{userId}/feedItems/{activityFeedItem}')
	.onCreate(async (snapshot, context) => {
		console.log('Activity feed item created', snapshot.data());
		// get user connected to the feed
		const userId = context.params.userId;
		
		const userRef = admin
			.firestore()
			.doc(`users/${userId}`);
		const doc = await userRef.get();
		// once we have user check if they have notification token if they have token
		const androidNotificationToken = doc.data().androidNotificationToken;
		const createdActivityFeedItem = snapshot.data();
		if (androidNotificationToken) {
			sendNotification(androidNotificationToken, createdActivityFeedItem)
		} else {
			console.log("no token for user. notification not sent")
		}

		function sendNotification(androidNotificationToken, activityFeedItem){
			let body;
			
			// switch body value based off of notification type
			switch (activityFeedItem.type) {
				case "comment":
					body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
					break;
				case "like":
					body = `${activityFeedItem.username} liked your post`;
					break;
				case "follow":
					body = `${activityFeedItem.username} started following you`;
					break;
				default:
					break;
			}

			// create message for push notification
			const message = {
				notification: { body },
				token: androidNotificationToken,
				data:{ recipient: userId }
			}

			//send message with admin.messaging()
			admin
				.messaging()
				.send(message)
				.then(response => {
					// message is message id stiring
					console.log("message sent successfully: ", response)
				})
				.catch(error => {
					console.log("error sending message: ", error)
				})
		}
	});