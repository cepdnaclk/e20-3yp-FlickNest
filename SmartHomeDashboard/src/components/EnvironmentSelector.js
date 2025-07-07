import React from 'react';
import { motion } from 'framer-motion';
import { ChevronDown, Home, Users } from 'lucide-react';

export default function EnvironmentSelector({ 
  environments, 
  currentEnvironment, 
  onEnvironmentChange 
}) {
  const [isOpen, setIsOpen] = React.useState(false);
  
  if (!environments || Object.keys(environments).length === 0) {
    return null;
  }

  const envList = Object.entries(environments).map(([id, env]) => ({
    id,
    ...env
  }));

  const current = envList.find(env => env.id === currentEnvironment);

  return (
    <div className="relative">
      <motion.button
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={() => setIsOpen(!isOpen)}
        className="glass-card rounded-xl p-4 flex items-center justify-between w-full min-w-64"
      >
        <div className="flex items-center space-x-3">
          <div className="p-2 rounded-lg bg-primary-500/20 text-primary-400">
            <Home size={20} />
          </div>
          <div className="text-left">
            <p className="font-semibold">{current?.name || 'Select Environment'}</p>
            <p className="text-sm text-gray-400">
              {current?.users ? Object.keys(current.users).length : 0} users
            </p>
          </div>
        </div>
        <ChevronDown className={`transition-transform ${isOpen ? 'rotate-180' : ''}`} size={20} />
      </motion.button>

      {isOpen && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          className="absolute top-full left-0 right-0 mt-2 glass-card rounded-xl p-2 z-50"
        >
          {envList.map((env) => (
            <motion.button
              key={env.id}
              whileHover={{ backgroundColor: 'rgba(255, 255, 255, 0.1)' }}
              onClick={() => {
                onEnvironmentChange(env.id);
                setIsOpen(false);
              }}
              className="w-full p-3 rounded-lg flex items-center space-x-3 text-left transition-colors"
            >
              <div className="p-2 rounded-lg bg-primary-500/20 text-primary-400">
                <Home size={16} />
              </div>
              <div className="flex-1">
                <p className="font-medium">{env.name}</p>
                <p className="text-sm text-gray-400">
                  {env.users ? Object.keys(env.users).length : 0} users
                </p>
              </div>
              {env.id === currentEnvironment && (
                <div className="w-2 h-2 rounded-full bg-primary-500" />
              )}
            </motion.button>
          ))}
        </motion.div>
      )}
    </div>
  );
}
