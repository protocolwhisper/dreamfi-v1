import { Card } from "@/components/ui/card";
import Link from "next/link";

export function Features() {
  return (
    <section className="container py-24">
      <div className="text-center mb-16">
        <h2 className="text-3xl font-semibold mb-4">Features</h2>
        <p className="text-muted-foreground">
          Discover all the main things that we do nicely
        </p>
      </div>

      <div className="grid grid-cols-3 gap-8 items-center">
        <Card className="p-4 hover:shadow-lg transition-shadow">
          <h3 className="text-xl font-semibold mb-4">Maker</h3>
          <ul className="space-y-3 text-sm text-muted-foreground">
            <li>Lorem ipsum dolor sit amet</li>
            <li>Consectetur adipiscing elit</li>
            <li>Sed do eiusmod tempor</li>
            <li>Ut labore et dolore magna</li>
          </ul>
        </Card>

        <Card className="p-8 scale-110 shadow-lg hover:shadow-xl transition-all">
          <h3 className="text-2xl font-semibold mb-4">Dream</h3>
          <ul className="space-y-4 text-muted-foreground">
            <li>Lorem ipsum dolor sit amet</li>
            <li>Consectetur adipiscing elit</li>
            <li>Sed do eiusmod tempor</li>
            <li>Ut labore et dolore magna</li>
            <li>Excepteur sint occaecat</li>
          </ul>
        </Card>

        <Card className="p-4 hover:shadow-lg transition-shadow">
          <h3 className="text-xl font-semibold mb-4">Reflexer</h3>
          <ul className="space-y-3 text-sm text-muted-foreground">
            <li>Lorem ipsum dolor sit amet</li>
            <li>Consectetur adipiscing elit</li>
            <li>Sed do eiusmod tempor</li>
            <li>Ut labore et dolore magna</li>
          </ul>
        </Card>
      </div>

      <div className="mt-16 text-center">
        <Link
          href="/app"
        >
          Launch App
        </Link>
      </div>
    </section>
  );
}
