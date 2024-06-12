import { Navigate, Outlet } from "react-router-dom"
import { useAuthContext } from "../context/AuthContext";

export const RootLayout = () => {
	const { authUser } = useAuthContext();
    
    if(authUser)
    return <Navigate to="/" replace/>

    return <Outlet />
}