import { Navigate, Outlet } from 'react-router-dom';
import { useAuthContext } from '../context/AuthContext';

export const ProtectedRoute = () => {
    const { authUser } = useAuthContext();

    if (!authUser)
    return <Navigate to="/login" replace />;

    return <Outlet />;
};