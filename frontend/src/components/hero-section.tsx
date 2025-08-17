import React from "react";
import { Badge } from "./ui/badge";
import { ArrowRight, Zap } from "lucide-react";
import { Button } from "./ui/button";

const HeroSection = () => {
  return (
    <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative">
      {/* Decorative financial grid lines */}
      <div className="absolute inset-0 -z-10 overflow-hidden">
        <div className="w-full h-full bg-[linear-gradient(to_right,rgba(0,0,0,0.05)_1px,transparent_1px),linear-gradient(to_bottom,rgba(0,0,0,0.05)_1px,transparent_1px)] bg-[size:40px_40px]" />
      </div>

      <div className="max-w-4xl mx-auto text-center py-20">
        {/* Badge */}
        <Badge
          variant="secondary"
          className="mb-6 bg-gradient-to-r from-emerald-100 to-emerald-50 text-emerald-700 border-emerald-200"
        >
          <Zap className="h-3 w-3 mr-1 text-emerald-500" />
          Powered by Ballerina
        </Badge>

        {/* Heading */}
        <h1 className="font-heading font-bold text-4xl sm:text-5xl lg:text-6xl text-foreground mb-6">
          Take Control of Your
          <span className="block bg-gradient-to-r from-emerald-500 via-green-600 to-emerald-700 bg-clip-text text-transparent">
            Financial Future
          </span>
        </h1>

        {/* Subtitle */}
        <p className="text-xl text-muted-foreground mb-10 max-w-2xl mx-auto leading-relaxed">
          Securely track spending, manage multiple accounts, set smart budgets,
          and analyze your financial patterns with our comprehensive personal
          finance platform.
        </p>

        {/* CTA */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button
            size="lg"
            className="text-lg px-8 text-white bg-gradient-to-r from-emerald-500 to-blue-600 shadow-lg shadow-emerald-200/50 hover:scale-105 transition-transform"
          >
            Start Tracking Your Finances
            <ArrowRight className="ml-2 h-5 w-5 text-yellow-300" />
          </Button>
        </div>
      </div>
    </div>
  );
};

export default HeroSection;
