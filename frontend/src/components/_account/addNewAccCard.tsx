import React, { Dispatch, SetStateAction } from "react";
import NewAccountDrawer from "./newAccountDrawer";
import { Wallet, CreditCard, Plus } from "lucide-react";

type NewCardProps = {
  isOpen: boolean;
  setIsOpen: Dispatch<SetStateAction<boolean>>;
};

const AddNewAccCard: React.FC<NewCardProps> = ({ isOpen, setIsOpen }) => {
  return (
    <NewAccountDrawer isOpen={isOpen} setIsOpen={setIsOpen}>
      <div className=" h-48 relative group cursor-pointer">
        {/* Main Card */}
        <div className="w-full h-full bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden relative transition-all duration-300 hover:shadow-lg">
          <div className="absolute inset-0 opacity-30">
            <div className="absolute top-4 right-4 w-16 h-16 rounded-full bg-gray-100 blur-2xl"></div>
            <div className="absolute bottom-4 left-4 w-12 h-12 rounded-full bg-gray-50 blur-xl"></div>
          </div>

          <div className="relative z-10 h-full flex flex-col justify-between p-6">
            {/* Top section */}
            <div className="flex justify-between items-start">
              <div className="flex items-center space-x-2">
                <Wallet className="h-5 w-5 text-gray-600" />
                <span className="text-gray-700 font-medium text-sm">
                  Account
                </span>
              </div>
              <CreditCard className="h-5 w-5 text-gray-400" />
            </div>

            <div className="flex flex-col items-center justify-center flex-1">
              <div className="w-12 h-12 rounded-full bg-gray-50 border border-gray-200 flex items-center justify-center mb-3 group-hover:bg-gray-100 transition-all duration-300">
                <Plus className="h-5 w-5 text-gray-600" />
              </div>
              <p className="text-gray-900 font-semibold text-lg">
                Add New Account
              </p>
            </div>

            <div className="flex justify-between items-end">
              <div className="flex space-x-1">
                <div className="w-2 h-2 rounded-full bg-gray-300"></div>
                <div className="w-2 h-2 rounded-full bg-gray-300"></div>
                <div className="w-2 h-2 rounded-full bg-gray-300"></div>
              </div>
              <div className="text-gray-400 text-xs font-mono">**** ****</div>
            </div>
          </div>

          <div className="absolute inset-0 rounded-2xl border border-transparent group-hover:border-gray-300 transition-all duration-300"></div>
        </div>

        <div className="absolute inset-0 bg-gray-100/50 rounded-2xl blur-xl opacity-0 group-hover:opacity-30 transition-opacity duration-300 -z-10"></div>
      </div>
    </NewAccountDrawer>
  );
};

export default AddNewAccCard;
