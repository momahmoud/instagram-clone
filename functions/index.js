const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("follower Created", snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // Create followed users posts
        const followedUserPostsRef = admin
            .firestore()
            .collection("posts")
            .doc(userId)
            .collection("userPosts");

        // Create following usre's timeline
        const timelinePostsRef = admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts");

        // get followed users posts
        const querySnapshot = await followedUserPostsRef.get();

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
    .onDelete(async (snapshot, context) => {
        console.log("follower delete", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        const timelinePostsRef = admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });

    });

exports.onCreatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onCreate(async (snapshot, context) => {
        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin.firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .set(postCreated);
        });
    });

exports.onUpdatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onUpdate(async (change, context) => {
        const postUpdate = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');
        const querySnapshot = await userFollowersRef.get();
        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin.firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {
                    if (doc.exists) {
                        doc.ref.update(postUpdate);
                    }
                });
        });
    });

exports.onDeletePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onDelete(async (snapshot, context) => {
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');
        const querySnapshot = await userFollowersRef.get();
        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin.firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                });
        });
    });

exports.onCreateActivityFeedItem = functions.firestore
    .document('/feed/{userId}/feedItems/{activityFeedItem}')
    .onCreate(async (snapshot, context) => {
        console.log('activity feed item created', snapshot.data());

        const userId = context.params.userId;
        const userRef = admin.firestore().doc( `users/${userId}`);
        const doc = await userRef.get();

        const androidNotificationToken = doc.data().androidNotificationToken;
        const createActivityFeedItem = snapshot.data();
        if (androidNotificationToken) {
            sendNotification(androidNotificationToken, createActivityFeedItem);
        } else {
            console.log('no token for user');
        }

        function sendNotification(androidNotificationToken, activityFeedItem) {
            let body;

            switch (activityFeedItem.type) {
                case "comment":
                    body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                    break;
                case "like":
                    body = `${activityFeedItem.username} likeed your post`;
                    break;
                case "follow":
                    body = `${activityFeedItem.username} following you`;
                    break;
                default:
                    break;
            }

            const message = {
                notification: { body },
                token: androidNotificationToken,
                data: { recipient: userId }
            };

            admin.messaging().send(message).then(ersponse => {
                console.log("successfully sent message", ersponse);
            }).catch(error => {
                console.log("Error sending message", error);
            });

        }

    });