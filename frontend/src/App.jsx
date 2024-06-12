import { Route, Routes } from "react-router-dom";
import "./App.css";
import Home from "./pages/home/Home";
import Login from "./pages/login/Login";
import SignUp from "./pages/signup/SignUp";
import { Toaster } from "react-hot-toast";
import { RootLayout } from "./layout/Root";
import { ProtectedRoute } from "./layout/Protected";

function App() {
	return (
		<div className='p-4 h-screen flex items-center justify-center'>
			<Routes>
				<Route element={<RootLayout/>}>
					<Route path='/login' element={<Login />} />
					<Route path='/signup' element={<SignUp />} />
					<Route element={<ProtectedRoute/>}>
						<Route path='/' element={<Home />} />
					</Route>
				</Route>
			</Routes>
			<Toaster />
		</div>
	);
}

export default App;
