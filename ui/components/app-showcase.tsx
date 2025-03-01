import { Card } from "./ui/card";

export function AppShowcase() {
  return (
    <section className="container py-24">
      <div className="text-center mb-16">
        <h2 className="text-3xl font-semibold mb-4 max-w-2xl mx-auto">
          Our all-in-one application
          is build for everybody
        </h2>
        <p className="text-muted-foreground max-w-2xl mx-auto">
          Dream&apos;s dashboard unify all the features in a
          simple and easy to use app
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        <Card className="overflow-hidden">
          <div className="p-4">
            <h3 className="text-xl font-semibold mb-2">Simplified Dashboard</h3>
            <p className="text-muted-foreground">Track the TVL, Price and Collateral Ratio</p>
          </div>
          <div className="border-t">
            <img 
              src="/dashboard-preview.png" 
              alt="Dashboard preview" 
              className="w-full h-[300px] object-cover"
            />
          </div>
        </Card>

        <Card className="overflow-hidden">
          <div className="p-4">
            <h3 className="text-xl font-semibold mb-2">Portfolio Manager</h3>
            <p className="text-muted-foreground">Track your portfolio</p>
          </div>
          <div className="border-t">
            <img 
              src="/portfolio-preview.png" 
              alt="Portfolio preview" 
              className="w-full h-[300px] object-cover"
            />
          </div>
        </Card>
      </div>
    </section>
  );
}
