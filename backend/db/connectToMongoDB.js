import mongoose from "mongoose";
const dbUrl =
  process.env.DB_URL ||
  "mongodb+srv://aniketsingh2704:lFMzlwdk4fFIE4IX@chat-app-cluster.h8genz4.mongodb.net/chat-app-db";


const connectToMongoDB = async () => {
	try {
		await mongoose.connect(process.env.dbUrl, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      // Other options if needed
    });
		console.log("Connected to MongoDB");
	} catch (error) {
		console.log("Error connecting to MongoDB", error.message);
	}
};

export default connectToMongoDB;
